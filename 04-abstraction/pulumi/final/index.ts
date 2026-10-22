import * as archive from "@pulumi/archive";
import { Service, ServiceArgs } from "./service";

const services: Record<string, ServiceArgs> = {
    api: { port: 8080, public: true },
    worker: { port: 9090 },
    admin: { port: 8081, public: true },
};

// Loop: one component per service
const deployed = Object.entries(services).map(([name, args]) => ({ name, svc: new Service(name, args) }));

// Terraform needs `dynamic` blocks for this. Here a nested block is just an array.
const bundle = archive.getFileOutput({
    type: "zip",
    outputPath: "out/bundle.zip",
    sources: deployed.map(({ name, svc }) => ({ filename: `${name}.json`, content: svc.config })),
});

export const configFiles = Object.fromEntries(deployed.map(({ name, svc }) => [name, svc.configFile]));
export const publicKeys = Object.fromEntries(
    deployed.filter(({ svc }) => svc.publicKey).map(({ name, svc }) => [name, svc.publicKey]),
);
export const bundlePath = bundle.outputPath;
