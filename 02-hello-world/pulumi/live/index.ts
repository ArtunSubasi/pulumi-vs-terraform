import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";

const config = new pulumi.Config();
const prefix = config.get("prefix") ?? "demo";

const name = new random.RandomPet("name", {
    prefix: prefix,
    length: 2,
});

// LIVE: new random.RandomPassword("db", ...) — length 20, no special characters

export const petName = name.id;
// LIVE: export the password — note it is marked [secret] automatically
