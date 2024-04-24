use std::path::PathBuf;

use async_trait::async_trait;
use chrono::{DateTime, Local};
use clap::{Parser, Subcommand};

use comfy_table::Table;

use minerva::change::Change;
use minerva::error::{DatabaseError, Error, RuntimeError};
use minerva::trigger::{
    dump_trigger, get_notifications, list_triggers, load_trigger, load_trigger_from_file,
    AddTrigger, CreateNotifications, DeleteTrigger, DisableTrigger, EnableTrigger, RenameTrigger,
    UpdateTrigger, VerifyTrigger,
};

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerList {}

#[async_trait]
impl Cmd for TriggerList {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let triggers = list_triggers(&mut client)
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error listing triggers: {e}")))?;

        let mut table = Table::new();
        let style = "     ═╪ ┆          ";
        table.load_preset(style);
        table.set_header(vec![
            "Name",
            "Notification Store",
            "Granularity",
            "Default Interval",
            "Enabled",
        ]);
        for trigger in triggers {
            table.add_row(vec![
                trigger.0,
                trigger.1,
                trigger.2,
                trigger.3,
                trigger.5.to_string(),
            ]);
        }

        println!("{table}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerCreate {
    #[arg(
        short = 'v',
        long = "verify",
        help = "run basic verification commands after creation"
    )]
    verify: bool,
    #[arg(long = "enable", help = "enable the trigger after creation")]
    enable: bool,
    #[arg(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerCreate {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;

        println!("Loaded definition, creating trigger");

        let mut client = connect_db().await?;

        let change = AddTrigger {
            trigger,
            verify: self.verify,
            enable: self.enable,
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerDelete {
    #[arg(help = "trigger name")]
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

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerUpdate {
    #[arg(
        short = 'v',
        long = "verify",
        help = "run basic verification commands after update"
    )]
    verify: bool,
    #[arg(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TriggerUpdate {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;

        let mut client = connect_db().await?;

        let change = UpdateTrigger {
            trigger,
            verify: self.verify,
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerRename {
    #[arg(
        short = 'v',
        long = "verify",
        help = "run basic verification commands after rename"
    )]
    verify: bool,
    #[arg(help = "renamed trigger definition file")]
    definition: PathBuf,
    #[arg(help = "old trigger name")]
    old_name: String,
}

#[async_trait]
impl Cmd for TriggerRename {
    async fn run(&self) -> CmdResult {
        let trigger = load_trigger_from_file(&self.definition)?;

        if trigger.name == self.old_name {
            return Err(Error::Runtime(RuntimeError::from_msg(format!(
                "Old name is the same as new name: '{}' = '{}'",
                &self.old_name, &trigger.name
            ))));
        }

        let mut client = connect_db().await?;

        let change = RenameTrigger {
            trigger,
            verify: self.verify,
            old_name: self.old_name.clone(),
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerVerify {
    #[arg(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerVerify {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let change = VerifyTrigger {
            trigger_name: self.name.clone(),
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerEnable {
    #[arg(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerEnable {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let change = EnableTrigger {
            trigger_name: self.name.clone(),
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerDisable {
    #[arg(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerDisable {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let change = DisableTrigger {
            trigger_name: self.name.clone(),
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerPreviewNotifications {
    #[arg(help = "trigger name")]
    name: String,
    #[arg(help = "timestamp")]
    timestamp: DateTime<Local>,
}

#[async_trait]
impl Cmd for TriggerPreviewNotifications {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let triggers = get_notifications(&mut client, &self.name, self.timestamp)
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error getting notifications: {e}")))?;

        let mut table = Table::new();
        let style = "     ═╪ ┆          ";
        table.load_preset(style);
        table.set_header(vec!["entity_id", "timestamp", "weight", "details", "data"]);
        for trigger in triggers {
            table.add_row(vec![
                trigger.0.to_string(),
                trigger.1,
                trigger.2.to_string(),
                trigger.3,
                trigger.4,
            ]);
        }

        println!("{table}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerCreateNotifications {
    #[arg(long = "timestamp", help = "timestamp")]
    timestamp: Option<DateTime<Local>>,
    #[arg(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerCreateNotifications {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let change = CreateNotifications {
            trigger_name: self.name.clone(),
            timestamp: self.timestamp,
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerDump {
    #[arg(help = "trigger name")]
    name: String,
}

#[async_trait]
impl Cmd for TriggerDump {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let trigger = load_trigger(&mut client, &self.name).await?;

        let trigger_definition = dump_trigger(&trigger);

        println!("{trigger_definition}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TriggerOpt {
    #[command(subcommand)]
    command: TriggerOptCommands
}

#[derive(Debug, Subcommand, PartialEq)]
pub enum TriggerOptCommands {
    #[command(about = "list configured triggers")]
    List(TriggerList),
    #[command(about = "create a trigger")]
    Create(TriggerCreate),
    #[command(about = "delete a trigger")]
    Delete(TriggerDelete),
    #[command(about = "enable a trigger")]
    Enable(TriggerEnable),
    #[command(about = "disable a trigger")]
    Disable(TriggerDisable),
    #[command(about = "update a trigger")]
    Update(TriggerUpdate),
    #[command(about = "rename a trigger")]
    Rename(TriggerRename),
    #[command(about = "dump a trigger definition")]
    Dump(TriggerDump),
    #[command(about = "run basic verification on a trigger")]
    Verify(TriggerVerify),
    #[command(about = "preview notifications of a trigger")]
    PreviewNotifications(TriggerPreviewNotifications),
    #[command(about = "create notifications of a trigger")]
    CreateNotifications(TriggerCreateNotifications),
}

impl TriggerOpt {
    pub async fn run(&self) -> CmdResult {
        match &self.command {
            TriggerOptCommands::List(list) => list.run().await,
            TriggerOptCommands::Create(create) => create.run().await,
            TriggerOptCommands::Delete(delete) => delete.run().await,
            TriggerOptCommands::Enable(enable) => enable.run().await,
            TriggerOptCommands::Disable(disable) => disable.run().await,
            TriggerOptCommands::Update(update) => update.run().await,
            TriggerOptCommands::Rename(rename) => rename.run().await,
            TriggerOptCommands::Dump(dump) => dump.run().await,
            TriggerOptCommands::Verify(verify) => verify.run().await,
            TriggerOptCommands::PreviewNotifications(preview_notifications) => {
                preview_notifications.run().await
            }
            TriggerOptCommands::CreateNotifications(create_notifications) => {
                create_notifications.run().await
            }
        }
    }
}
