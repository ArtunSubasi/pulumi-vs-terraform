import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";

const config = new pulumi.Config();
const prefix = config.get("prefix") ?? "demo";

const name = new random.RandomPet("name", {
    prefix: prefix,
    length: 2,
});

const db = new random.RandomPassword("db", {
    length: 20,
    special: false,
});

export const petName = name.id;
export const password = db.result;
