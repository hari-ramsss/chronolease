use cosmwasm_schema::cw_serde;
use cosmwasm_std::{
    entry_point, to_json_binary, Addr, Deps, DepsMut, Env, MessageInfo, Response, StdError,
    StdResult, Uint128,
};
use cw_storage_plus::Item;
use thiserror::Error;

const CONTRACT_NAME: &str = "crates.io:qorelease-staking-probe";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");
const QOR_DENOM: &str = "uqor";

const LAST_RESULT: Item<ProbeResult> = Item::new("last_result");

#[cw_serde]
pub struct InstantiateMsg {}

#[cw_serde]
pub enum ExecuteMsg {
    /// Runs CosmWasm's standard `StakingQuery::AllDelegations` route and stores
    /// the raw delegation denominations plus the checked `uqor` aggregate.
    Probe { provider: String },
}

#[cw_serde]
pub enum QueryMsg {
    LastResult {},
}

#[cw_serde]
pub struct DelegationSnapshot {
    pub validator: String,
    pub denom: String,
    pub amount: Uint128,
}

#[cw_serde]
pub struct ProbeResult {
    pub provider: String,
    pub total_uqor: Uint128,
    pub delegations: Vec<DelegationSnapshot>,
    pub observed_at_height: u64,
}

#[derive(Error, Debug, PartialEq)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),
}

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    cw2::set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    Ok(Response::new().add_attribute("action", "instantiate"))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    _info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Probe { provider } => probe(deps, env, provider),
    }
}

fn probe(deps: DepsMut, env: Env, provider: String) -> Result<Response, ContractError> {
    let provider_address: Addr = deps.api.addr_validate(&provider)?;
    let delegations_response = deps
        .querier
        .query_all_delegations(provider_address.as_str())?;

    let mut total_uqor = Uint128::zero();
    let delegations = delegations_response
        .into_iter()
        .map(|delegation| {
            if delegation.amount.denom == QOR_DENOM {
                total_uqor = total_uqor.checked_add(delegation.amount.amount)?;
            }
            Ok(DelegationSnapshot {
                validator: delegation.validator,
                denom: delegation.amount.denom,
                amount: delegation.amount.amount,
            })
        })
        .collect::<StdResult<Vec<_>>>()?;

    let result = ProbeResult {
        provider,
        total_uqor,
        delegations,
        observed_at_height: env.block.height,
    };
    LAST_RESULT.save(deps.storage, &result)?;

    Ok(Response::new()
        .add_attribute("action", "probe")
        .add_attribute("provider", result.provider)
        .add_attribute("total_uqor", result.total_uqor))
}

#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<cosmwasm_std::Binary> {
    match msg {
        QueryMsg::LastResult {} => to_json_binary(&LAST_RESULT.load(deps.storage)?),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use cosmwasm_std::{
        coin,
        testing::{mock_dependencies, mock_env, mock_info},
        FullDelegation,
    };

    const PROVIDER: &str = "qor1provider";

    #[test]
    fn stores_checked_uqor_total_and_raw_denominations() {
        let mut deps = mock_dependencies();
        deps.querier.update_staking(
            "uqor",
            &[],
            &[
                FullDelegation {
                    delegator: Addr::unchecked(PROVIDER),
                    validator: "qorvaloper1first".into(),
                    amount: coin(1_500_000, "uqor"),
                    can_redelegate: coin(0, "uqor"),
                    accumulated_rewards: vec![],
                },
                FullDelegation {
                    delegator: Addr::unchecked(PROVIDER),
                    validator: "qorvaloper1second".into(),
                    amount: coin(2_000_000, "other"),
                    can_redelegate: coin(0, "uqor"),
                    accumulated_rewards: vec![],
                },
            ],
        );

        instantiate(
            deps.as_mut(),
            mock_env(),
            mock_info("creator", &[]),
            InstantiateMsg {},
        )
        .unwrap();
        probe(deps.as_mut(), mock_env(), PROVIDER.into()).unwrap();

        let result = LAST_RESULT.load(&deps.storage).unwrap();
        assert_eq!(result.total_uqor, Uint128::new(1_500_000));
        assert_eq!(result.delegations.len(), 2);
        assert_eq!(result.delegations[1].denom, "other");
    }

    #[test]
    fn stores_zero_for_provider_without_delegations() {
        let mut deps = mock_dependencies();
        deps.querier.update_staking("uqor", &[], &[]);
        instantiate(
            deps.as_mut(),
            mock_env(),
            mock_info("creator", &[]),
            InstantiateMsg {},
        )
        .unwrap();

        probe(deps.as_mut(), mock_env(), PROVIDER.into()).unwrap();

        assert_eq!(
            LAST_RESULT.load(&deps.storage).unwrap().total_uqor,
            Uint128::zero()
        );
    }
}
