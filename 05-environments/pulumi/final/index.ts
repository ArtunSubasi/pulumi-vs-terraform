import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as local from "@pulumi/local";

// One program, one stack per environment: config comes from Pulumi.<stack>.yaml
const stack = pulumi.getStack();
const config = new pulumi.Config();
const instanceCount = config.requireNumber("instanceCount");
const logLevel = config.require("logLevel"); // default comes from the schema in Pulumi.yaml

const instances: random.RandomPet[] = [];
for (let i = 0; i < instanceCount; i++) {
    instances.push(new random.RandomPet(`instance-${i}`, { prefix: stack }));
}
const names = instances.map(pet => pet.id);

new local.File("settings", {
    filename: `out/${stack}.json`,
    content: pulumi.jsonStringify({ environment: stack, log_level: logLevel, instances: names }),
}, { deleteBeforeReplace: true });

export const instanceNames = names;
