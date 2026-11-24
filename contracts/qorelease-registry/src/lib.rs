use cosmwasm_schema::cw_serde;
use cosmwasm_std::{
    coin, entry_point, to_json_binary, Addr, BankMsg, Binary, Coin, Deps, DepsMut, Env,
    MessageInfo, Response, StdError, StdResult, Uint128,
};
use cw_storage_plus::{Item, Map};
use thiserror::Error;

const CONTRACT_NAME: &str = "crates.io:qorelease-registry";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");
const QOR_DENOM: &str = "uqor";
const BPS: u128 = 10_000;

const CONFIG: Item<Config> = Item::new("config");
const PROVIDERS: Map<&str, Provider> = Map::new("providers");
const PROVIDER_BY_OWNER: Map<&Addr, String> = Map::new("provider_by_owner");
const SLOTS: Map<(&str, &str), Slot> = Map::new("slots");
const LAST_SLOT: Map<&str, String> = Map::new("last_slot");
// Reservation records are retained after completion. Their presence is the replay guard.
const RESERVATIONS: Map<&str, Reservation> = Map::new("reservations");

#[cw_serde]
pub struct InstantiateMsg {
    pub admin: String,
    /// The mapped Native identity of the one EVM escrow authorized to reserve/finalize.
    pub authorized_escrow: String,
    pub penalty_recipient: String,
    pub minimum_stake_uqor: Uint128,
    pub bond_per_unit_uqor: Uint128,
    pub breach_penalty_bps: u16,
}

#[cw_serde]
pub enum ExecuteMsg {
    RegisterProvider {
        provider_id: String,
        service_profile: String,
        endpoint_manifest_hash: String,
    },
    DepositBond {},
    WithdrawBond { amount: Uint128 },
    PublishSlot {
        slot_id: String,
        service_type: String,
        start_time: u64,
        end_time: u64,
        total_units: Uint128,
        terms_hash: String,
    },
    Reserve {
        job_id: String,
        provider_id: String,
        slot_id: String,
        units: Uint128,
        terms_hash: String,
        slot_terms_hash: String,
    },
    Finalize {
        job_id: String,
        terms_hash: String,
        delivered_units: Uint128,
        accepted_breach: bool,
    },
    Release { job_id: String },
    UpdateConfig {
        minimum_stake_uqor: Option<Uint128>,
        bond_per_unit_uqor: Option<Uint128>,
        breach_penalty_bps: Option<u16>,
        authorized_escrow: Option<String>,
        penalty_recipient: Option<String>,
    },
}

#[cw_serde]
pub enum QueryMsg {
    Provider { provider_id: String },
    Slot { provider_id: String, slot_id: String },
    Reservation { job_id: String },
    AvailableCapacity { provider_id: String, slot_id: String },
    ProviderBond { provider_id: String },
    Config {},
}

#[cw_serde]
pub struct Config {
    pub admin: Addr,
    pub authorized_escrow: Addr,
    pub penalty_recipient: Addr,
    pub minimum_stake_uqor: Uint128,
    pub bond_per_unit_uqor: Uint128,
    pub breach_penalty_bps: u16,
}

#[cw_serde]
pub struct Provider {
    pub provider_id: String,
    pub owner: Addr,
    pub service_profile: String,
    pub endpoint_manifest_hash: String,
    pub verified_stake_uqor: Uint128,
    pub active: bool,
}

#[cw_serde]
pub struct Slot {
    pub provider_id: String,
    pub slot_id: String,
    pub service_type: String,
    pub start_time: u64,
    pub end_time: u64,
    pub total_units: Uint128,
    pub reserved_units: Uint128,
    pub consumed_units: Uint128,
    pub terms_hash: String,
    pub active: bool,
}

#[cw_serde]
pub struct ProviderBond {
    pub provider_id: String,
    pub available_uqor: Uint128,
    pub locked_uqor: Uint128,
    /// Cumulative penalties paid to the configured recipient (not part of current balance).
    pub penalties_paid_uqor: Uint128,
    pub withdrawn_uqor: Uint128,
    pub total_deposited_uqor: Uint128,
}

#[cw_serde]
pub struct Reservation {
    pub job_id: String,
    pub provider_id: String,
    pub slot_id: String,
    pub terms_hash: String,
    pub units: Uint128,
    pub delivered_units: Uint128,
    pub locked_bond_uqor: Uint128,
    pub created_at: u64,
    pub expires_at: u64,
    pub status: ReservationStatus,
}

#[cw_serde]
pub enum ReservationStatus {
    Active,
    Finalized,
    Released,
}

#[cw_serde]
pub struct SlotView {
    pub slot: Slot,
    pub available_units: Uint128,
}

#[cw_serde]
pub struct BondView {
    pub bond: ProviderBond,
    pub withdrawable_uqor: Uint128,
}

#[cw_serde]
struct WireResponse {
    version: u8,
    operation: u8,
    job_id: String,
    terms_hash: String,
    reserved_units: Uint128,
    delivered_units: Uint128,
    available_units: Uint128,
}

#[derive(Error, Debug, PartialEq)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),
    #[error("unauthorized")]
    Unauthorized,
    #[error("invalid input: {0}")]
    InvalidInput(String),
    #[error("provider already registered")]
    ProviderAlreadyRegistered,
    #[error("provider not found")]
    ProviderNotFound,
    #[error("provider is inactive or below the staking threshold")]
    ProviderIneligible,
    #[error("reservation capacity is insufficient")]
    InsufficientCapacity,
    #[error("available provider bond is insufficient")]
    InsufficientBond,
    #[error("job ID has already been used")]
    DuplicateJob,
    #[error("reservation is not active")]
    InvalidReservationState,
    #[error("slot is expired")]
    SlotExpired,
    #[error("wrong funds: deposit exactly one non-zero uqor coin")]
    InvalidFunds,
}

#[entry_point]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    if msg.breach_penalty_bps > 10_000 {
        return Err(ContractError::InvalidInput(
            "breach_penalty_bps must be <= 10000".into(),
        ));
    }
    let config = Config {
        admin: deps.api.addr_validate(&msg.admin)?,
        authorized_escrow: deps.api.addr_validate(&msg.authorized_escrow)?,
        penalty_recipient: deps.api.addr_validate(&msg.penalty_recipient)?,
        minimum_stake_uqor: msg.minimum_stake_uqor,
        bond_per_unit_uqor: msg.bond_per_unit_uqor,
        breach_penalty_bps: msg.breach_penalty_bps,
    };
    CONFIG.save(deps.storage, &config)?;
    cw2::set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    Ok(Response::new().add_attribute("action", "instantiate"))
}

#[entry_point]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::RegisterProvider {
            provider_id,
            service_profile,
            endpoint_manifest_hash,
        } => register_provider(
            deps,
            info,
            provider_id,
            service_profile,
            endpoint_manifest_hash,
        ),
        ExecuteMsg::DepositBond {} => deposit_bond(deps, info),
        ExecuteMsg::WithdrawBond { amount } => withdraw_bond(deps, info, amount),
        ExecuteMsg::PublishSlot {
            slot_id,
            service_type,
            start_time,
            end_time,
            total_units,
            terms_hash,
        } => publish_slot(
            deps,
            env,
            info,
            slot_id,
            service_type,
            start_time,
            end_time,
            total_units,
            terms_hash,
        ),
        ExecuteMsg::Reserve {
            job_id,
            provider_id,
            slot_id,
            units,
            terms_hash,
            slot_terms_hash,
        } => reserve(
            deps,
            env,
            info,
            job_id,
            provider_id,
            slot_id,
            units,
            terms_hash,
            slot_terms_hash,
        ),
        ExecuteMsg::Finalize {
            job_id,
            terms_hash,
            delivered_units,
            accepted_breach,
        } => finalize(
            deps,
            info,
            job_id,
            terms_hash,
            delivered_units,
            accepted_breach,
        ),
        ExecuteMsg::Release { job_id } => release(deps, env, info, job_id),
        ExecuteMsg::UpdateConfig {
            minimum_stake_uqor,
            bond_per_unit_uqor,
            breach_penalty_bps,
            authorized_escrow,
            penalty_recipient,
        } => update_config(
            deps,
            info,
            minimum_stake_uqor,
            bond_per_unit_uqor,
            breach_penalty_bps,
            authorized_escrow,
            penalty_recipient,
        ),
    }
}

fn register_provider(
    deps: DepsMut,
    info: MessageInfo,
    provider_id: String,
    service_profile: String,
    endpoint_manifest_hash: String,
) -> Result<Response, ContractError> {
    validate_identifier(&provider_id, "provider_id")?;
    validate_hash(&endpoint_manifest_hash, "endpoint_manifest_hash")?;
    if service_profile.trim().is_empty() || service_profile.len() > 512 {
        return Err(ContractError::InvalidInput(
            "service_profile must contain 1..=512 bytes".into(),
        ));
    }
    if PROVIDERS.may_load(deps.storage, &provider_id)?.is_some()
        || PROVIDER_BY_OWNER
            .may_load(deps.storage, &info.sender)?
            .is_some()
    {
        return Err(ContractError::ProviderAlreadyRegistered);
    }
    let config = CONFIG.load(deps.storage)?;
    let stake = query_uqor_delegations(deps.as_ref(), &info.sender)?;
    if stake < config.minimum_stake_uqor {
        return Err(ContractError::ProviderIneligible);
    }
    let provider = Provider {
        provider_id: provider_id.clone(),
        owner: info.sender.clone(),
        service_profile,
        endpoint_manifest_hash,
        verified_stake_uqor: stake,
        active: true,
    };
    PROVIDERS.save(deps.storage, &provider_id, &provider)?;
    PROVIDER_BY_OWNER.save(deps.storage, &info.sender, &provider_id)?;
    Ok(Response::new()
        .add_attribute("action", "register_provider")
        .add_attribute("provider_id", provider_id)
        .add_attribute("verified_stake_uqor", stake))
}

fn deposit_bond(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    let amount = exact_qor_funds(&info.funds)?;
    let provider_id = provider_id_for_owner(deps.as_ref(), &info.sender)?;
    let mut bond = load_bond(deps.storage, &provider_id)?;
    bond.available_uqor = bond
        .available_uqor
        .checked_add(amount)
        .map_err(StdError::overflow)?;
    bond.total_deposited_uqor = bond
        .total_deposited_uqor
        .checked_add(amount)
        .map_err(StdError::overflow)?;
    save_bond(deps.storage, &bond)?;
    Ok(Response::new()
        .add_attribute("action", "deposit_bond")
        .add_attribute("provider_id", provider_id)
        .add_attribute("amount_uqor", amount))
}

fn withdraw_bond(
    deps: DepsMut,
    info: MessageInfo,
    amount: Uint128,
) -> Result<Response, ContractError> {
    if !info.funds.is_empty() || amount.is_zero() {
        return Err(ContractError::InvalidFunds);
    }
    let provider_id = provider_id_for_owner(deps.as_ref(), &info.sender)?;
    let mut bond = load_bond(deps.storage, &provider_id)?;
    if bond.available_uqor < amount {
        return Err(ContractError::InsufficientBond);
    }
    bond.available_uqor = bond
        .available_uqor
        .checked_sub(amount)
        .map_err(StdError::overflow)?;
    bond.withdrawn_uqor = bond
        .withdrawn_uqor
        .checked_add(amount)
        .map_err(StdError::overflow)?;
    save_bond(deps.storage, &bond)?;
    Ok(Response::new()
        .add_message(BankMsg::Send {
            to_address: info.sender.to_string(),
            amount: vec![coin(amount.u128(), QOR_DENOM)],
        })
        .add_attribute("action", "withdraw_bond")
        .add_attribute("provider_id", provider_id)
        .add_attribute("amount_uqor", amount))
}

#[allow(clippy::too_many_arguments)]
fn publish_slot(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    slot_id: String,
    service_type: String,
    start_time: u64,
    end_time: u64,
    total_units: Uint128,
    terms_hash: String,
) -> Result<Response, ContractError> {
    let mut deps = deps;
    check_slot_staking(&mut deps, &info.sender)?;
    validate_identifier(&slot_id, "slot_id")?;
    validate_identifier(&service_type, "service_type")?;
    validate_hash(&terms_hash, "terms_hash")?;
    if !info.funds.is_empty() {
        return Err(ContractError::InvalidFunds);
    }
    if start_time >= end_time || end_time <= env.block.time.seconds() || total_units.is_zero() {
        return Err(ContractError::InvalidInput(
            "slot needs start_time < end_time, a future end_time and non-zero total_units".into(),
        ));
    }
    let provider_id = provider_id_for_owner(deps.as_ref(), &info.sender)?;
    let provider = PROVIDERS.load(deps.storage, &provider_id)?;
    if !provider.active {
        return Err(ContractError::ProviderIneligible);
    }
    if let Some(last_slot_id) = LAST_SLOT.may_load(deps.storage, &provider_id)? {
        let previous = SLOTS.load(deps.storage, (&provider_id, &last_slot_id))?;
        if start_time < previous.end_time {
            return Err(ContractError::InvalidInput(
                "provider slots must be published in chronological, non-overlapping order".into(),
            ));
        }
    }
    if SLOTS
        .may_load(deps.storage, (&provider_id, &slot_id))?
        .is_some()
    {
        return Err(ContractError::InvalidInput(
            "slot_id cannot be reused".into(),
        ));
    }
    SLOTS.save(
        deps.storage,
        (&provider_id, &slot_id),
        &Slot {
            provider_id: provider_id.clone(),
            slot_id: slot_id.clone(),
            service_type,
            start_time,
            end_time,
            total_units,
            reserved_units: Uint128::zero(),
            consumed_units: Uint128::zero(),
            terms_hash,
            active: true,
        },
    )?;
    LAST_SLOT.save(deps.storage, &provider_id, &slot_id)?;
    Ok(Response::new()
        .add_attribute("action", "publish_slot")
        .add_attribute("provider_id", provider_id)
        .add_attribute("slot_id", slot_id))
}

#[allow(clippy::too_many_arguments)]
fn reserve(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    job_id: String,
    provider_id: String,
    slot_id: String,
    units: Uint128,
    terms_hash: String,
    slot_terms_hash: String,
) -> Result<Response, ContractError> {
    if !info.funds.is_empty() {
        return Err(ContractError::InvalidFunds);
    }
    validate_job_id(&job_id)?;
    validate_identifier(&provider_id, "provider_id")?;
    validate_identifier(&slot_id, "slot_id")?;
    validate_hash(&terms_hash, "terms_hash")?;
    validate_hash(&slot_terms_hash, "slot_terms_hash")?;
    if units.is_zero() {
        return Err(ContractError::InvalidInput("units must be non-zero".into()));
    }
    let config = CONFIG.load(deps.storage)?;
    if info.sender != config.authorized_escrow {
        return Err(ContractError::Unauthorized);
    }
    if RESERVATIONS.may_load(deps.storage, &job_id)?.is_some() {
        return Err(ContractError::DuplicateJob);
    }
    let mut provider = PROVIDERS
        .may_load(deps.storage, &provider_id)?
        .ok_or(ContractError::ProviderNotFound)?;
    if !provider.active {
        return Err(ContractError::ProviderIneligible);
    }
    // Recheck the Native staking source at reservation time; query errors propagate (fail closed).
    let stake = query_uqor_delegations(deps.as_ref(), &provider.owner)?;
    if stake < config.minimum_stake_uqor {
        return Err(ContractError::ProviderIneligible);
    }
    provider.verified_stake_uqor = stake;
    PROVIDERS.save(deps.storage, &provider_id, &provider)?;

    let mut slot = SLOTS
        .may_load(deps.storage, (&provider_id, &slot_id))?
        .ok_or_else(|| StdError::not_found("slot"))?;
    if !slot.active || env.block.time.seconds() >= slot.end_time {
        return Err(ContractError::SlotExpired);
    }
    if slot.terms_hash != slot_terms_hash {
        return Err(ContractError::InvalidInput(
            "slot_terms_hash does not match published slot".into(),
        ));
    }
    let available = available_units(&slot)?;
    if available < units {
        return Err(ContractError::InsufficientCapacity);
    }
    let locked = config
        .bond_per_unit_uqor
        .checked_mul(units)
        .map_err(StdError::overflow)?;
    let mut bond = load_bond(deps.storage, &provider_id)?;
    if bond.available_uqor < locked {
        return Err(ContractError::InsufficientBond);
    }
    bond.available_uqor = bond
        .available_uqor
        .checked_sub(locked)
        .map_err(StdError::overflow)?;
    bond.locked_uqor = bond
        .locked_uqor
        .checked_add(locked)
        .map_err(StdError::overflow)?;
    slot.reserved_units = slot
        .reserved_units
        .checked_add(units)
        .map_err(StdError::overflow)?;
    save_bond(deps.storage, &bond)?;
    SLOTS.save(deps.storage, (&provider_id, &slot_id), &slot)?;
    let reservation = Reservation {
        job_id: job_id.clone(),
        provider_id: provider_id.clone(),
        slot_id,
        terms_hash: terms_hash.clone(),
        units,
        delivered_units: Uint128::zero(),
        locked_bond_uqor: locked,
        created_at: env.block.time.seconds(),
        expires_at: slot.end_time,
        status: ReservationStatus::Active,
    };
    RESERVATIONS.save(deps.storage, &job_id, &reservation)?;
    let remaining = available
        .checked_sub(units)
        .map_err(StdError::overflow)?;
    Ok(wire_response(
        1,
        &job_id,
        &terms_hash,
        units,
        Uint128::zero(),
        remaining,
    )
    .add_attribute("action", "reserve")
    .add_attribute("provider_id", provider_id)
    .add_attribute("slot_id", reservation.slot_id))
}

fn finalize(
    deps: DepsMut,
    info: MessageInfo,
    job_id: String,
    terms_hash: String,
    delivered_units: Uint128,
    accepted_breach: bool,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    if info.sender != config.authorized_escrow {
        return Err(ContractError::Unauthorized);
    }
    let mut reservation = RESERVATIONS
        .may_load(deps.storage, &job_id)?
        .ok_or_else(|| StdError::not_found("reservation"))?;
    if reservation.status != ReservationStatus::Active {
        return Err(ContractError::InvalidReservationState);
    }
    if reservation.terms_hash != terms_hash {
        return Err(ContractError::InvalidInput(
            "terms_hash does not match reservation".into(),
        ));
    }
    if delivered_units > reservation.units {
        return Err(ContractError::InvalidInput(
            "delivered_units exceeds reserved units".into(),
        ));
    }
    let mut slot = SLOTS.load(
        deps.storage,
        (&reservation.provider_id, &reservation.slot_id),
    )?;
    let mut bond = load_bond(deps.storage, &reservation.provider_id)?;
    let penalty = if accepted_breach {
        reservation
            .locked_bond_uqor
            .checked_mul(Uint128::from(config.breach_penalty_bps as u128))
            .map_err(StdError::overflow)?
            .checked_div(Uint128::from(BPS))
            .map_err(StdError::divide_by_zero)?
    } else {
        Uint128::zero()
    };
    let returned = reservation
        .locked_bond_uqor
        .checked_sub(penalty)
        .map_err(StdError::overflow)?;
    bond.locked_uqor = bond
        .locked_uqor
        .checked_sub(reservation.locked_bond_uqor)
        .map_err(StdError::overflow)?;
    bond.available_uqor = bond
        .available_uqor
        .checked_add(returned)
        .map_err(StdError::overflow)?;
    bond.penalties_paid_uqor = bond
        .penalties_paid_uqor
        .checked_add(penalty)
        .map_err(StdError::overflow)?;
    slot.reserved_units = slot
        .reserved_units
        .checked_sub(reservation.units)
        .map_err(StdError::overflow)?;
    slot.consumed_units = slot
        .consumed_units
        .checked_add(delivered_units)
        .map_err(StdError::overflow)?;
    reservation.delivered_units = delivered_units;
    reservation.status = ReservationStatus::Finalized;
    let remaining = available_units(&slot)?;
    SLOTS.save(
        deps.storage,
        (&reservation.provider_id, &reservation.slot_id),
        &slot,
    )?;
    save_bond(deps.storage, &bond)?;
    RESERVATIONS.save(deps.storage, &job_id, &reservation)?;
    let mut response = wire_response(
        2,
        &job_id,
        &terms_hash,
        reservation.units,
        delivered_units,
        remaining,
    )
    .add_attribute("action", "finalize")
    .add_attribute("penalty_uqor", penalty)
    .add_attribute("returned_bond_uqor", returned);
    if !penalty.is_zero() {
        response = response.add_message(BankMsg::Send {
            to_address: config.penalty_recipient.to_string(),
            amount: vec![coin(penalty.u128(), QOR_DENOM)],
        });
    }
    Ok(response)
}

fn release(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    job_id: String,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    let mut reservation = RESERVATIONS
        .may_load(deps.storage, &job_id)?
        .ok_or_else(|| StdError::not_found("reservation"))?;
    if reservation.status != ReservationStatus::Active {
        return Err(ContractError::InvalidReservationState);
    }
    if info.sender != config.authorized_escrow && env.block.time.seconds() < reservation.expires_at
    {
        return Err(ContractError::Unauthorized);
    }
    let mut slot = SLOTS.load(
        deps.storage,
        (&reservation.provider_id, &reservation.slot_id),
    )?;
    let mut bond = load_bond(deps.storage, &reservation.provider_id)?;
    slot.reserved_units = slot
        .reserved_units
        .checked_sub(reservation.units)
        .map_err(StdError::overflow)?;
    bond.locked_uqor = bond
        .locked_uqor
        .checked_sub(reservation.locked_bond_uqor)
        .map_err(StdError::overflow)?;
    bond.available_uqor = bond
        .available_uqor
        .checked_add(reservation.locked_bond_uqor)
        .map_err(StdError::overflow)?;
    reservation.status = ReservationStatus::Released;
    let remaining = available_units(&slot)?;
    SLOTS.save(
        deps.storage,
        (&reservation.provider_id, &reservation.slot_id),
        &slot,
    )?;
    save_bond(deps.storage, &bond)?;
    RESERVATIONS.save(deps.storage, &job_id, &reservation)?;
    Ok(wire_response(
        3,
        &job_id,
        &reservation.terms_hash,
        reservation.units,
        Uint128::zero(),
        remaining,
    )
    .add_attribute("action", "release"))
}

fn update_config(
    deps: DepsMut,
    info: MessageInfo,
    minimum_stake_uqor: Option<Uint128>,
    bond_per_unit_uqor: Option<Uint128>,
    breach_penalty_bps: Option<u16>,
    authorized_escrow: Option<String>,
    penalty_recipient: Option<String>,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;
    if info.sender != config.admin {
        return Err(ContractError::Unauthorized);
    }
    if let Some(value) = breach_penalty_bps {
        if value > 10_000 {
            return Err(ContractError::InvalidInput(
                "breach_penalty_bps must be <= 10000".into(),
            ));
        }
        config.breach_penalty_bps = value;
    }
    if let Some(value) = minimum_stake_uqor {
        config.minimum_stake_uqor = value;
    }
    if let Some(value) = bond_per_unit_uqor {
        config.bond_per_unit_uqor = value;
    }
    if let Some(value) = authorized_escrow {
        config.authorized_escrow = deps.api.addr_validate(&value)?;
    }
    if let Some(value) = penalty_recipient {
        config.penalty_recipient = deps.api.addr_validate(&value)?;
    }
    CONFIG.save(deps.storage, &config)?;
    Ok(Response::new().add_attribute("action", "update_config"))
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Provider { provider_id } => {
            to_json_binary(&PROVIDERS.load(deps.storage, &provider_id)?)
        }
        QueryMsg::Slot {
            provider_id,
            slot_id,
        } => {
            let slot = SLOTS.load(deps.storage, (&provider_id, &slot_id))?;
            to_json_binary(&SlotView {
                available_units: if env.block.time.seconds() >= slot.end_time {
                    Uint128::zero()
                } else {
                    available_units(&slot)?
                },
                slot,
            })
        }
        QueryMsg::Reservation { job_id } => {
            to_json_binary(&RESERVATIONS.load(deps.storage, &job_id)?)
        }
        QueryMsg::AvailableCapacity {
            provider_id,
            slot_id,
        } => {
            let slot = SLOTS.load(deps.storage, (&provider_id, &slot_id))?;
            let available = if env.block.time.seconds() >= slot.end_time {
                Uint128::zero()
            } else {
                available_units(&slot)?
            };
            to_json_binary(&available)
        }
        QueryMsg::ProviderBond { provider_id } => {
            let bond = load_bond(deps.storage, &provider_id)?;
            to_json_binary(&BondView {
                withdrawable_uqor: bond.available_uqor,
                bond,
            })
        }
        QueryMsg::Config {} => to_json_binary(&CONFIG.load(deps.storage)?),
    }
}

/// Isolated standard-library staking query. QoreChain Diana support and the meaning
/// of AllDelegations (bonded versus unbonding) remain deployment gates.
fn query_uqor_delegations(deps: Deps, provider: &Addr) -> StdResult<Uint128> {
    let delegations = deps.querier.query_all_delegations(provider.as_str())?;
    delegations
        .iter()
        .filter(|delegation| delegation.amount.denom == QOR_DENOM)
        .try_fold(Uint128::zero(), |total, delegation| {
            total.checked_add(delegation.amount.amount)
        })
        .map_err(StdError::overflow)
}

fn check_slot_staking(deps: &mut DepsMut<'_>, owner: &Addr) -> Result<Uint128, ContractError> {
    let config = CONFIG.load(deps.storage)?;
    let provider_id = PROVIDER_BY_OWNER
        .may_load(deps.storage, owner)?
        .ok_or(ContractError::ProviderNotFound)?;
    let mut provider = PROVIDERS
        .may_load(deps.storage, &provider_id)?
        .ok_or(ContractError::ProviderNotFound)?;
    if !provider.active {
        return Err(ContractError::ProviderIneligible);
    }
    let stake = query_uqor_delegations(deps.as_ref(), &provider.owner)?;
    if stake < config.minimum_stake_uqor {
        return Err(ContractError::ProviderIneligible);
    }
    provider.verified_stake_uqor = stake;
    PROVIDERS.save(deps.storage, &provider_id, &provider)?;
    Ok(stake)
}

fn provider_id_for_owner(deps: Deps, owner: &Addr) -> Result<String, ContractError> {
    PROVIDER_BY_OWNER
        .may_load(deps.storage, owner)?
        .ok_or(ContractError::ProviderNotFound)
}

fn load_bond(storage: &dyn cosmwasm_std::Storage, provider_id: &str) -> StdResult<ProviderBond> {
    BONDS
        .may_load(storage, provider_id)?
        .map(Ok)
        .unwrap_or_else(|| {
            if PROVIDERS.may_load(storage, provider_id)?.is_none() {
                return Err(StdError::not_found("provider"));
            }
            Ok(ProviderBond {
                provider_id: provider_id.to_string(),
                available_uqor: Uint128::zero(),
                locked_uqor: Uint128::zero(),
                penalties_paid_uqor: Uint128::zero(),
                total_deposited_uqor: Uint128::zero(),
                withdrawn_uqor: Uint128::zero(),
            })
        })
}

const BONDS: Map<&str, ProviderBond> = Map::new("bonds");

fn save_bond(storage: &mut dyn cosmwasm_std::Storage, bond: &ProviderBond) -> StdResult<()> {
    BONDS.save(storage, &bond.provider_id, bond)
}

fn exact_qor_funds(funds: &[Coin]) -> Result<Uint128, ContractError> {
    if funds.len() != 1 || funds[0].denom != QOR_DENOM || funds[0].amount.is_zero() {
        return Err(ContractError::InvalidFunds);
    }
    Ok(funds[0].amount)
}

fn available_units(slot: &Slot) -> StdResult<Uint128> {
    slot.total_units
        .checked_sub(slot.reserved_units)
        .and_then(|value| value.checked_sub(slot.consumed_units))
        .map_err(StdError::overflow)
}

fn validate_identifier(value: &str, field: &str) -> Result<(), ContractError> {
    if value.is_empty()
        || value.len() > 64
        || !value
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
    {
        return Err(ContractError::InvalidInput(format!(
            "{field} must be 1..=64 ASCII letters, digits, '-' or '_'"
        )));
    }
    Ok(())
}

fn validate_hash(value: &str, field: &str) -> Result<(), ContractError> {
    if value.len() != 66
        || !value.starts_with("0x")
        || !value[2..].bytes().all(|byte| byte.is_ascii_hexdigit())
    {
        return Err(ContractError::InvalidInput(format!(
            "{field} must be a 0x-prefixed 32-byte hex value"
        )));
    }
    Ok(())
}

fn validate_job_id(value: &str) -> Result<(), ContractError> {
    validate_hash(value, "job_id")
}

fn wire_response(
    operation: u8,
    job_id: &str,
    terms_hash: &str,
    reserved_units: Uint128,
    delivered_units: Uint128,
    available_units: Uint128,
) -> Response {
    let wire = WireResponse {
        version: 1,
        operation,
        job_id: job_id.to_string(),
        terms_hash: terms_hash.to_string(),
        reserved_units,
        delivered_units,
        available_units,
    };
    Response::new().set_data(encode_wire_response(&wire))
}

/// Proposed v1 bridge return payload: seven 32-byte ABI words, no dynamic offsets.
/// Its shape is deliberate and locally tested, but the Diana precompile's handling
/// of CosmWasm Response.data has NOT been verified.
fn encode_wire_response(wire: &WireResponse) -> Binary {
    let mut output = Vec::with_capacity(7 * 32);
    push_u128_word(&mut output, wire.version as u128);
    push_u128_word(&mut output, wire.operation as u128);
    push_bytes32_word(&mut output, &wire.job_id);
    push_bytes32_word(&mut output, &wire.terms_hash);
    push_u128_word(&mut output, wire.reserved_units.u128());
    push_u128_word(&mut output, wire.delivered_units.u128());
    push_u128_word(&mut output, wire.available_units.u128());
    Binary::from(output)
}

fn push_u128_word(output: &mut Vec<u8>, value: u128) {
    output.extend_from_slice(&[0; 16]);
    output.extend_from_slice(&value.to_be_bytes());
}

fn push_bytes32_word(output: &mut Vec<u8>, hex: &str) {
    let mut decoded = [0u8; 32];
    for (index, pair) in hex.as_bytes()[2..].chunks_exact(2).enumerate() {
        decoded[index] = (hex_digit(pair[0]) << 4) | hex_digit(pair[1]);
    }
    output.extend_from_slice(&decoded);
}

fn hex_digit(value: u8) -> u8 {
    match value {
        b'0'..=b'9' => value - b'0',
        b'a'..=b'f' => value - b'a' + 10,
        b'A'..=b'F' => value - b'A' + 10,
        _ => unreachable!("hash is validated before encoding"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use cosmwasm_std::{
        coin,
        testing::{mock_dependencies, mock_env, mock_info},
        FullDelegation, Querier, QuerierResult, SystemError, SystemResult, Uint128,
    };

    const ADMIN: &str = "admin";
    const ESCROW: &str = "escrow";
    const PROVIDER: &str = "provider-a";
    const PROVIDER_ID: &str = "provider-a";
    const SLOT_ID: &str = "slot-1";
    const JOB_A: &str =
        "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    const JOB_B: &str =
        "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    const HASH: &str =
        "0x1111111111111111111111111111111111111111111111111111111111111111";
    const ENDPOINT_HASH: &str =
        "0x2222222222222222222222222222222222222222222222222222222222222222";

    struct FailingStakingQuerier;

    impl Querier for FailingStakingQuerier {
        fn raw_query(&self, _request: &[u8]) -> QuerierResult {
            SystemResult::Err(SystemError::UnsupportedRequest {
                kind: "controlled staking-query failure".into(),
            })
        }
    }

    fn setup() -> cosmwasm_std::OwnedDeps<
        cosmwasm_std::MemoryStorage,
        cosmwasm_std::testing::MockApi,
        cosmwasm_std::testing::MockQuerier,
    > {
        let mut deps = mock_dependencies();
        instantiate(
            deps.as_mut(),
            mock_env(),
            mock_info("creator", &[]),
            InstantiateMsg {
                admin: ADMIN.into(),
                authorized_escrow: ESCROW.into(),
                penalty_recipient: "treasury".into(),
                minimum_stake_uqor: Uint128::new(100),
                bond_per_unit_uqor: Uint128::new(2),
                breach_penalty_bps: 1_000,
            },
        )
        .unwrap();
        set_stake(&mut deps, PROVIDER, &[coin(100, QOR_DENOM)]);
        deps
    }

    fn set_stake(
        deps: &mut cosmwasm_std::OwnedDeps<
            cosmwasm_std::MemoryStorage,
            cosmwasm_std::testing::MockApi,
            cosmwasm_std::testing::MockQuerier,
        >,
        provider: &str,
        amounts: &[Coin],
    ) {
        let entries = amounts
            .iter()
            .enumerate()
            .map(|(index, amount)| FullDelegation {
                delegator: Addr::unchecked(provider),
                validator: format!("qorvaloper1validator{index}"),
                amount: amount.clone(),
                can_redelegate: coin(0, QOR_DENOM),
                accumulated_rewards: vec![],
            })
            .collect::<Vec<_>>();
        deps.querier.update_staking(QOR_DENOM, &[], &entries);
    }

    fn register(deps: DepsMut) {
        register_provider(
            deps,
            mock_info(PROVIDER, &[]),
            PROVIDER_ID.into(),
            "document-extraction".into(),
            ENDPOINT_HASH.into(),
        )
        .unwrap();
    }

    fn deposit(deps: DepsMut, amount: u128) {
        deposit_bond(deps, mock_info(PROVIDER, &[coin(amount, QOR_DENOM)])).unwrap();
    }

    fn publish(deps: DepsMut, env: Env, capacity: u128) -> Result<Response, ContractError> {
        publish_slot(
            deps,
            env,
            mock_info(PROVIDER, &[]),
            SLOT_ID.into(),
            "inference-api".into(),
            1_700_000_000,
            1_800_000_000,
            Uint128::new(capacity),
            HASH.into(),
        )
    }

    fn reserve(
        deps: DepsMut,
        env: Env,
        job: &str,
        units: u128,
    ) -> Result<Response, ContractError> {
        reserve_with(deps, env, job, units, HASH, HASH)
    }

    #[allow(clippy::too_many_arguments)]
    fn reserve_with(
        deps: DepsMut,
        env: Env,
        job: &str,
        units: u128,
        slot_terms_hash: &str,
        job_terms_hash: &str,
    ) -> Result<Response, ContractError> {
        super::reserve(
            deps,
            env,
            mock_info(ESCROW, &[]),
            job.into(),
            PROVIDER_ID.into(),
            SLOT_ID.into(),
            Uint128::new(units),
            job_terms_hash.into(),
            slot_terms_hash.into(),
        )
    }

    fn setup_slot(capacity: u128, bond: u128) -> cosmwasm_std::OwnedDeps<
        cosmwasm_std::MemoryStorage,
        cosmwasm_std::testing::MockApi,
        cosmwasm_std::testing::MockQuerier,
    > {
        let mut deps = setup();
        register(deps.as_mut());
        deposit(deps.as_mut(), bond);
        let mut env = mock_env();
        env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);
        publish(deps.as_mut(), env, capacity).unwrap();
        deps
    }

    #[test]
    fn provider_registration_requires_stake_and_stores_identity() {
        let mut deps = setup();
        register(deps.as_mut());
        let provider = PROVIDERS.load(&deps.storage, PROVIDER_ID).unwrap();
        assert_eq!(provider.owner, Addr::unchecked(PROVIDER));
        assert_eq!(provider.verified_stake_uqor, Uint128::new(100));

        let mut low = setup();
        set_stake(&mut low, PROVIDER, &[coin(99, QOR_DENOM)]);
        let err = register_provider(
            low.as_mut(),
            mock_info(PROVIDER, &[]),
            PROVIDER_ID.into(),
            "profile".into(),
            ENDPOINT_HASH.into(),
        )
        .unwrap_err();
        assert_eq!(err, ContractError::ProviderIneligible);
    }

    #[test]
    fn staking_sums_only_uqor_with_checked_arithmetic() {
        let mut deps = setup();
        set_stake(
            &mut deps,
            PROVIDER,
            &[coin(80, QOR_DENOM), coin(21, QOR_DENOM), coin(900, "other")],
        );
        assert_eq!(
            query_uqor_delegations(deps.as_ref(), &Addr::unchecked(PROVIDER)).unwrap(),
            Uint128::new(101)
        );
        set_stake(
            &mut deps,
            PROVIDER,
            &[
                Coin {
                    denom: QOR_DENOM.into(),
                    amount: Uint128::MAX,
                },
                coin(1, QOR_DENOM),
            ],
        );
        assert!(query_uqor_delegations(deps.as_ref(), &Addr::unchecked(PROVIDER)).is_err());
    }

    #[test]
    fn staking_query_errors_are_propagated_fail_closed() {
        let deps = setup();
        let failing = FailingStakingQuerier;
        let query_deps = Deps {
            storage: &deps.storage,
            api: &deps.api,
            querier: cosmwasm_std::QuerierWrapper::new(&failing),
        };
        assert!(query_uqor_delegations(query_deps, &Addr::unchecked(PROVIDER)).is_err());
    }

    #[test]
    fn bond_deposit_requires_native_uqor_and_tracks_available_amount() {
        let mut deps = setup();
        register(deps.as_mut());
        deposit(deps.as_mut(), 1_000);
        assert_eq!(
            load_bond(&deps.storage, PROVIDER_ID).unwrap().available_uqor,
            Uint128::new(1_000)
        );
        let wrong = deposit_bond(
            deps.as_mut(),
            mock_info(PROVIDER, &[coin(1_000, "fUSD")]),
        )
        .unwrap_err();
        assert_eq!(wrong, ContractError::InvalidFunds);
        let multiple = deposit_bond(
            deps.as_mut(),
            mock_info(PROVIDER, &[coin(1, QOR_DENOM), coin(1, QOR_DENOM)]),
        )
        .unwrap_err();
        assert_eq!(multiple, ContractError::InvalidFunds);
    }

    #[test]
    fn successful_reservation_locks_bond_and_capacity_then_release_restores_both() {
        let mut deps = setup_slot(100, 1_000);
        let mut env = mock_env();
        env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_001);
        reserve(deps.as_mut(), env.clone(), JOB_A, 70).unwrap();
        let slot = SLOTS.load(&deps.storage, (PROVIDER_ID, SLOT_ID)).unwrap();
        let bond = load_bond(&deps.storage, PROVIDER_ID).unwrap();
        assert_eq!(available_units(&slot).unwrap(), Uint128::new(30));
        assert_eq!(bond.available_uqor, Uint128::new(860));
        assert_eq!(bond.locked_uqor, Uint128::new(140));

        release(deps.as_mut(), env, mock_info(ESCROW, &[]), JOB_A.into()).unwrap();
        let slot = SLOTS.load(&deps.storage, (PROVIDER_ID, SLOT_ID)).unwrap();
        let bond = load_bond(&deps.storage, PROVIDER_ID).unwrap();
        assert_eq!(available_units(&slot).unwrap(), Uint128::new(100));
        assert_eq!(bond.available_uqor, Uint128::new(1_000));
        assert_eq!(bond.locked_uqor, Uint128::zero());
    }

    #[test]
    fn overlapping_slot_publication_is_rejected() {
        let mut deps = setup_slot(100, 1_000);
        let mut env = mock_env();
        env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);
        let error = publish_slot(
            deps.as_mut(),
            env,
            mock_info(PROVIDER, &[]),
            "slot-overlap".into(),
            "other-service".into(),
            1_799_000_000,
            1_810_000_000,
            Uint128::new(50),
            HASH.into(),
        )
        .unwrap_err();
        assert!(matches!(error, ContractError::InvalidInput(_)));
    }

    #[test]
    fn rejects_insufficient_capacity_bond_duplicate_job_and_unauthorized_sender() {
        let mut deps = setup_slot(100, 100);
        let mut env = mock_env();
        env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);
        assert_eq!(
            reserve(deps.as_mut(), env.clone(), JOB_A, 60).unwrap_err(),
            ContractError::InsufficientBond
        );
        // Replenish collateral to exercise capacity/duplicate guards.
        deposit(deps.as_mut(), 1_000);
        reserve(deps.as_mut(), env.clone(), JOB_A, 70).unwrap();
        assert_eq!(
            reserve(deps.as_mut(), env.clone(), JOB_B, 50).unwrap_err(),
            ContractError::InsufficientCapacity
        );
        assert_eq!(
            reserve(deps.as_mut(), env.clone(), JOB_A, 1).unwrap_err(),
            ContractError::DuplicateJob
        );
        let unauthorized = super::reserve(
            deps.as_mut(),
            env,
            mock_info("stranger", &[]),
            "0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc".into(),
            PROVIDER_ID.into(),
            SLOT_ID.into(),
            Uint128::new(1),
            HASH.into(),
            HASH.into(),
        )
        .unwrap_err();
        assert_eq!(unauthorized, ContractError::Unauthorized);
    }

    #[test]
    fn expired_slots_cannot_be_reserved_and_only_expired_reservations_are_permissionlessly_released() {
        let mut deps = setup_slot(10, 100);
        let mut before_expiry = mock_env();
        before_expiry.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);
        reserve(deps.as_mut(), before_expiry.clone(), JOB_A, 2).unwrap();
        let unauthorized = release(
            deps.as_mut(),
            before_expiry.clone(),
            mock_info("stranger", &[]),
            JOB_A.into(),
        )
        .unwrap_err();
        assert_eq!(unauthorized, ContractError::Unauthorized);

        let mut after_expiry = mock_env();
        after_expiry.block.time = cosmwasm_std::Timestamp::from_seconds(1_800_000_000);
        assert_eq!(
            reserve(deps.as_mut(), after_expiry.clone(), JOB_B, 1).unwrap_err(),
            ContractError::SlotExpired
        );
        release(
            deps.as_mut(),
            after_expiry,
            mock_info("anyone", &[]),
            JOB_A.into(),
        )
        .unwrap();
    }

    #[test]
    fn finalize_checks_state_and_accounts_breach_penalty_once() {
        let mut deps = setup_slot(100, 1_000);
        let mut env = mock_env();
        env.block.time = cosmwasm_std::Timestamp::from_seconds(1_750_000_000);
        reserve(deps.as_mut(), env, JOB_A, 70).unwrap();
        let response = finalize(
            deps.as_mut(),
            mock_info(ESCROW, &[]),
            JOB_A.into(),
            HASH.into(),
            Uint128::new(60),
            true,
        )
        .unwrap();
        assert_eq!(response.messages.len(), 1);
        assert_eq!(
            response.messages[0].msg,
            BankMsg::Send {
                to_address: "treasury".into(),
                amount: vec![coin(14, QOR_DENOM)],
            }
            .into()
        );
        let bond = load_bond(&deps.storage, PROVIDER_ID).unwrap();
        assert_eq!(bond.available_uqor, Uint128::new(986));
        assert_eq!(bond.locked_uqor, Uint128::zero());
        assert_eq!(bond.penalties_paid_uqor, Uint128::new(14));
        let slot = SLOTS.load(&deps.storage, (PROVIDER_ID, SLOT_ID)).unwrap();
        assert_eq!(slot.consumed_units, Uint128::new(60));
        assert_eq!(available_units(&slot).unwrap(), Uint128::new(40));
        assert_eq!(
            finalize(
                deps.as_mut(),
                mock_info(ESCROW, &[]),
                JOB_A.into(),
                HASH.into(),
                Uint128::new(60),
                true
            )
            .unwrap_err(),
            ContractError::InvalidReservationState
        );
    }

    #[test]
    fn wire_response_has_strict_seven_word_layout() {
        let data = encode_wire_response(&WireResponse {
            version: 1,
            operation: 1,
            job_id: JOB_A.into(),
            terms_hash: HASH.into(),
            reserved_units: Uint128::new(70),
            delivered_units: Uint128::zero(),
            available_units: Uint128::new(30),
        });
        assert_eq!(data.len(), 224);
        assert_eq!(&data[0..32], &[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
        assert_eq!(&data[64..96], &[0xaa; 32]);
    }

    #[test]
    fn admin_can_change_staking_threshold_but_non_admin_cannot() {
        let mut deps = setup();
        assert_eq!(
            update_config(
                deps.as_mut(),
                mock_info("stranger", &[]),
                Some(Uint128::new(200)),
                None,
                None,
                None,
                None
            )
            .unwrap_err(),
            ContractError::Unauthorized
        );
        update_config(
            deps.as_mut(),
            mock_info(ADMIN, &[]),
            Some(Uint128::new(200)),
            None,
            None,
            None,
            None,
        )
        .unwrap();
        assert_eq!(
            CONFIG.load(&deps.storage).unwrap().minimum_stake_uqor,
            Uint128::new(200)
        );
    }
}
