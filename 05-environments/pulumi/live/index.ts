import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as local from "@pulumi/local";

// One program, one stack per environment: config comes from Pulumi.<stack>.yaml
const stack = pulumi.getStack();
const config = new pulumi.Config();
// LIVE: instanceCount = config.requireNumber(...), logLevel = config.require(...)
const instanceCount = 0;
const logLevel = "TODO";

const instances: random.RandomPet[] = [];
// LIVE: for loop — one RandomPet(`instance-${i}`, { prefix: stack }) per instance
const names = instances.map(pet => pet.id);

new local.File("settings", {
    filename: `out/${stack}.json`,
    content: pulumi.jsonStringify({ environment: stack, log_level: logLevel, instances: names }),
}, { deleteBeforeReplace: true });

export const instanceNames = names;
