import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as local from "@pulumi/local";

export interface ServiceArgs {
    port: number;
}

export class Service extends pulumi.ComponentResource {
    public readonly config: pulumi.Output<string>;
    public readonly configFile: pulumi.Output<string>;
    public readonly connectionString: pulumi.Output<string>;

    constructor(name: string, args: ServiceArgs, opts?: pulumi.ComponentResourceOptions) {
        // Validation is plain code: it runs before anything is created
        if (!/^[a-z][a-z0-9-]*$/.test(name)) {
            throw new Error(`name must be lowercase letters, digits and dashes: "${name}"`);
        }
        if (args.port < 1024 || args.port > 65535) {
            throw new Error(`port must be between 1024 and 65535 (no privileged ports): ${args.port}`);
        }
        super("demo:index:Service", name, {}, opts);

        const db = new random.RandomPassword(`${name}-db`, {
            length: 20,
            special: false,
        }, { parent: this });

        this.config = pulumi.jsonStringify({ service: name, port: args.port, db_password: db.result });

        const file = new local.File(`${name}-config`, {
            filename: `out/${name}.json`,
            content: this.config,
        }, { parent: this, deleteBeforeReplace: true });
        this.configFile = file.filename;

        this.connectionString = pulumi.interpolate`postgres://${name}:${db.result}@db.internal:5432/${name}`;

        this.registerOutputs({ configFile: this.configFile, connectionString: this.connectionString });
    }
}
