//! LOCAL END-TO-END NATIVE SCENARIO (mocked staking queries).
//!
//! This drives the real `qorelease-registry` entry points with a controlled
//! staking-query mock. It is NOT a Diana integration test. It proves that using
//! the actual Native contract code, a slot of 100 units cannot be overbooked by
//! a second 50-unit reservation after 70 units are reserved, and that finalizing
//! the first reservation consumes only delivered units.

use qorelease_registry::{
    execute, instantiate, query, ContractError, ExecuteMsg, InstantiateMsg, QueryMsg,
};
use cosmwasm_std::{
    coin, from_json,
    testing::{mock_dependencies, mock_env, mock_info},
    Addr, FullDelegation, Uint128,
};

const ADMIN: &str = "admin";
const ESCROW: &str = "escrow-mapped-identity";
const PROVIDER: &str = "provider-a";
const TREASURY: &str = "treasury";
const JOB_A: &str = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const JOB_B: &str = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
const HASH: &str = "0x1111111111111111111111111111111111111111111111111111111111111111";
const ENDPOINT_HASH: &str = "0x2222222222222222222222222222222222222222222222222222222222222222";

#[test]
fn local_e2e_no_overbooking_and_finalization() {
    let mut deps = mock_dependencies();
    deps.querier.update_staking(
        "uqor",
        &[],
        &[FullDelegation {
            delegator: Addr::unchecked(PROVIDER),
            validator: "qorvaloper1validator".into(),
            amount: coin(500, "uqor"),
            can_redelegate: coin(0, "uqor"),
            accumulated_rewards: vec![],
        }],
    );
    let mut env = mock_env();
    env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);

    // 1. Instantiate registry with configured eligibility and escrow identity.
    instantiate(
        deps.as_mut(),
        env.clone(),
        mock_info(ADMIN, &[]),
        InstantiateMsg {
            admin: ADMIN.into(),
            authorized_escrow: ESCROW.into(),
            penalty_recipient: TREASURY.into(),
            minimum_stake_uqor: Uint128::new(100),
            bond_per_unit_uqor: Uint128::new(2),
            breach_penalty_bps: 1_000,
        },
    )
    .unwrap();

    // 2. Provider A registers with a valid mocked uqor delegation.
    execute(
        deps.as_mut(),
        env.clone(),
        mock_info(PROVIDER, &[]),
        ExecuteMsg::RegisterProvider {
            provider_id: PROVIDER.into(),
            service_profile: "document-extraction-v1".into(),
            endpoint_manifest_hash: ENDPOINT_HASH.into(),
        },
    )
    .unwrap();

    // 3. Provider A deposits QOR collateral through the Native funds field.
    execute(
        deps.as_mut(),
        env.clone(),
        mock_info(PROVIDER, &[coin(1_000, "uqor")]),
        ExecuteMsg::DepositBond {},
    )
    .unwrap();

    // 4. Provider A publishes a 100-unit slot.
    execute(
        deps.as_mut(),
        env.clone(),
        mock_info(PROVIDER, &[]),
        ExecuteMsg::PublishSlot {
            slot_id: "slot-1".into(),
            service_type: "inference-api".into(),
            start_time: 1_700_000_000,
            end_time: 1_800_000_000,
            total_units: Uint128::new(100),
            terms_hash: HASH.into(),
        },
    )
    .unwrap();

    // 5-6. Buyer A reserves 70 units through the authorized escrow identity.
    let reserve_a = execute(
        deps.as_mut(),
        env.clone(),
        mock_info(ESCROW, &[]),
        ExecuteMsg::Reserve {
            job_id: JOB_A.into(),
            provider_id: PROVIDER.into(),
            slot_id: "slot-1".into(),
            units: Uint128::new(70),
            terms_hash: HASH.into(),
            slot_terms_hash: HASH.into(),
        },
    )
    .unwrap();
    let data = reserve_a.data.expect("reserve response must carry wire data");
    assert_eq!(data.len(), 224, "strict seven-word bridge response");

    let available: Uint128 = from_json(
        query(
            deps.as_ref(),
            env.clone(),
            QueryMsg::AvailableCapacity {
                provider_id: PROVIDER.into(),
                slot_id: "slot-1".into(),
            },
        )
        .unwrap(),
    )
    .unwrap();
    assert_eq!(available, Uint128::new(30));

    // 7-9. Buyer B attempts 50 units. Only 30 remain -> Native rejects; in the
    //       Solidity flow this revert rolls back buyer B's fUSD escrow transfer.
    let error = execute(
        deps.as_mut(),
        env.clone(),
        mock_info(ESCROW, &[]),
        ExecuteMsg::Reserve {
            job_id: JOB_B.into(),
            provider_id: PROVIDER.into(),
            slot_id: "slot-1".into(),
            units: Uint128::new(50),
            terms_hash: HASH.into(),
            slot_terms_hash: HASH.into(),
        },
    )
    .unwrap_err();
    assert_eq!(error, ContractError::InsufficientCapacity);

    let available_after: Uint128 = from_json(
        query(
            deps.as_ref(),
            env.clone(),
            QueryMsg::AvailableCapacity {
                provider_id: PROVIDER.into(),
                slot_id: "slot-1".into(),
            },
        )
        .unwrap(),
    )
    .unwrap();
    assert_eq!(available_after, Uint128::new(30), "no capacity leaked on failure");

    // 13. Native finalization consumes delivered units and unlocks bond.
    execute(
        deps.as_mut(),
        env,
        mock_info(ESCROW, &[]),
        ExecuteMsg::Finalize {
            job_id: JOB_A.into(),
            terms_hash: HASH.into(),
            delivered_units: Uint128::new(70),
            accepted_breach: false,
        },
    )
    .unwrap();

    let bond: qorelease_registry::BondView = from_json(
        query(
            deps.as_ref(),
            mock_env(),
            QueryMsg::ProviderBond {
                provider_id: PROVIDER.into(),
            },
        )
        .unwrap(),
    )
    .unwrap();
    assert_eq!(bond.bond.available_uqor, Uint128::new(1_000));
    assert_eq!(bond.bond.locked_uqor, Uint128::zero());
    assert_eq!(bond.withdrawable_uqor, Uint128::new(1_000));
}
