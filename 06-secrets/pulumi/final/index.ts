import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as local from "@pulumi/local";

// Set it outside the code:  pulumi config set --secret apiToken ...
const config = new pulumi.Config();
const apiToken = config.requireSecret("apiToken");

const db = new random.RandomPassword("db", {
    length: 20,
    special: false,
});

// Secretness propagates: anything built from a secret is a secret.
export const connectionString = pulumi.interpolate`postgres://app:${db.result}@db.internal:5432/app`;
export const tokenLength = apiToken.apply(t => t.length);

// Mark a plain value as secret yourself
export const adminUser = pulumi.secret("admin");

new local.SensitiveFile("env", {
    filename: "out/.env",
    content: pulumi.interpolate`API_TOKEN=${apiToken}\nDB_PASSWORD=${db.result}\n`,
}, { deleteBeforeReplace: true });
