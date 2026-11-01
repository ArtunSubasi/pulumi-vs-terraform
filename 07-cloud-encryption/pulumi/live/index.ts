import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";

// Same program as 06-secrets, minus the file. What changed is the stack's secrets provider:
// AWS KMS instead of a passphrase (see Pulumi.dev.yaml after `pulumi stack init`).
const config = new pulumi.Config();
const apiToken = config.requireSecret("apiToken");

const db = new random.RandomPassword("db", {
    length: 20,
    special: false,
});

// LIVE: export password (db.result) and tokenLength (from apiToken)
