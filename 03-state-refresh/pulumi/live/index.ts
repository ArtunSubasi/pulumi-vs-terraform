import * as random from "@pulumi/random";
// Generated from the Terraform provider: pulumi package add terraform-provider hashicorp/local 2.9.1
import * as local from "@pulumi/local";

const db = new random.RandomPassword("db", {
    length: 16,
    special: false,
});

// A file on disk is the cheapest "real" resource: easy to change behind the tool's back.
// LIVE: new local.File("config", ...) — filename "out/app.conf", content "db_user=app\nport=5432\n"

// LIVE: export const configFile
