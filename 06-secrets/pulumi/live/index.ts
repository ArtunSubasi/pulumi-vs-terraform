import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as local from "@pulumi/local";

// Set it outside the code:  pulumi config set --secret apiToken ...
const config = new pulumi.Config();
// LIVE: const apiToken = config.requireSecret("apiToken")
const apiToken = pulumi.output("TODO");

const db = new random.RandomPassword("db", {
    length: 20,
    special: false,
});

// Secretness propagates: anything built from a secret is a secret.
// LIVE: export connectionString = pulumi.interpolate`postgres://app:${db.result}@db.internal:5432/app`
// LIVE: export tokenLength = apiToken.apply(t => t.length)

// LIVE: export adminUser = pulumi.secret("admin")

new local.SensitiveFile("env", {
    filename: "out/.env",
    content: pulumi.interpolate`API_TOKEN=${apiToken}\nDB_PASSWORD=${db.result}\n`,
}, { deleteBeforeReplace: true });
