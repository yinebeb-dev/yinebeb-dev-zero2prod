use secrecy::ExposeSecret;
use sqlx::postgres::PgPoolOptions;
use std::net::TcpListener;

use zero2prod::configuration::get_configuration;
use zero2prod::startup::run;
use zero2prod::telemetry::{get_subscriber, init_subscriber};

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let subscriber = get_subscriber("zero2prod".into(), "info".into(), std::io::stdout);
    init_subscriber(subscriber);
    // Panic if we can't read configuration
    let configuration = get_configuration().expect("Failed to read configuration.");
    // setup connection
    // No longer async, given that we don't actually try to connect!
    let connection_pool = PgPoolOptions::new()
        .connect_timeout(std::time::Duration::from_secs(2))        
        .connect_lazy(&configuration.database.connection_string().expose_secret())
        .expect("Failed to create Postgres connection pool.");
    // We have removed the hard-coded `8000` - it's now coming from our settings!
    let address = format!(
        "{}:{}", 
        configuration.application.host,
        configuration.application.port
    );
    let listener = TcpListener::bind(address)?;
    run(listener, connection_pool)?.await
}
