use std::path::PathBuf;

use async_trait::async_trait;
use structopt::StructOpt;

use minerva::error::DatabaseError;
use minerva::change::Change;
use minerva::trigger::{
    list_triggers, load_trigger_from_file, AddTrigger, DeleteTrigger, UpdateTriggerData,
    UpdateTriggerKPIFunction, UpdateTrigger,
};

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, StructOpt)]
pub struct TriggerList {}

#[async_trait]
impl Cmd for TriggerList {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let triggers = list_triggers(&mut client).await.map_err(|e| DatabaseError::from_msg(format!("Error listing triggers: {}", e)))?;

        for trigger in triggers {
            println!("{}", &trigger);
        }

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TriggerCreate {
    #[structopt(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerCreate {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;
        let trigger_name = trigger.name.clone();

        println!("Loaded definition, creating trigger");

        let mut client = connect_db().await?;

        let change = AddTrigger { trigger };

        change.apply(&mut client).await?;

        println!("Created trigger '{}'", &trigger_name);

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TriggerDelete {
    #[structopt(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerDelete {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let change = DeleteTrigger {
            trigger_name: self.name.clone(),
        };

        change.apply(&mut client).await?;

        println!("Deleted trigger '{}'", &self.name);

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TriggerUpdateData {
    #[structopt(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerUpdateData {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;
        let trigger_name = trigger.name.clone();

        let mut client = connect_db().await?;

        let change = UpdateTriggerData { trigger };

        change.apply(&mut client).await?;

        println!("Updated data definition of trigger '{}'", &trigger_name);

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TriggerUpdateKPIFunction {
    #[structopt(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerUpdateKPIFunction {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;
        let trigger_name = trigger.name.clone();

        let mut client = connect_db().await?;

        let change = UpdateTriggerKPIFunction { trigger };

        change.apply(&mut client).await?;

        println!("Updated KPI function of trigger '{}'", &trigger_name);

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TriggerUpdate {
    #[structopt(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerUpdate {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;
        let trigger_name = trigger.name.clone();

        let mut client = connect_db().await?;

        let change = UpdateTrigger { trigger };

        change.apply(&mut client).await?;

        println!("Updated trigger '{}'", &trigger_name);

        Ok(())
    }
}


#[derive(Debug, StructOpt)]
pub enum TriggerOpt {
    #[structopt(about = "list configured triggers")]
    List(TriggerList),
    #[structopt(about = "create a trigger")]
    Create(TriggerCreate),
    #[structopt(about = "delete a trigger")]
    Delete(TriggerDelete),
    #[structopt(about = "update a trigger")]
    Update(TriggerUpdate),
    #[structopt(about = "update data definition of a trigger")]
    UpdateData(TriggerUpdateData),
    #[structopt(about = "update KPI function of a trigger")]
    UpdateKPIFunction(TriggerUpdateKPIFunction),
}

impl TriggerOpt {
    pub async fn run(&self) -> CmdResult {
        match self {
            TriggerOpt::List(list) => list.run().await,
            TriggerOpt::Create(create) => create.run().await,
            TriggerOpt::Delete(delete) => delete.run().await,
            TriggerOpt::Update(update) => update.run().await,
            TriggerOpt::UpdateData(update_data) => update_data.run().await,
            TriggerOpt::UpdateKPIFunction(update_kpi_function) => update_kpi_function.run().await,
        }
    }
}
