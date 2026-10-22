import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import * as tls from "@pulumi/tls";
import * as local from "@pulumi/local";

export interface ServiceArgs {
    port: number;
    public?: boolean;
}

// The equivalent of the Terraform module: a typed, reusable class
export class Service extends pulumi.ComponentResource {
    public readonly config: pulumi.Output<string>;
    public readonly configFile: pulumi.Output<string>;
    public readonly publicKey?: pulumi.Output<string>;

    constructor(name: string, args: ServiceArgs, opts?: pulumi.ComponentResourceOptions) {
        super("demo:index:Service", name, {}, opts);

        const db = new random.RandomPassword(`${name}-db`, {
            length: 20,
            special: false,
        }, { parent: this });

        // db.result is an Output<string>, not a string: JSON.stringify() can't see inside it.
        this.config = pulumi.jsonStringify({
            service: name,
            port: args.port,
            db_password: db.result,
        });

        const file = new local.File(`${name}-config`, {
            filename: `out/${name}.json`,
            content: this.config,
        }, {
            parent: this,
            // Pulumi replaces create-before-delete by default. Same filename → the delete
            // would remove the new file. (Terraform's default is destroy-before-create.)
            deleteBeforeReplace: true,
        });
        this.configFile = file.filename;

        // Conditional resource: a plain `if`
        if (args.public) {
            const key = new tls.PrivateKey(`${name}-tls`, { algorithm: "ED25519" }, { parent: this });
            this.publicKey = key.publicKeyOpenssh.apply(k => k.trim());
        }

        this.registerOutputs({ configFile: this.configFile, publicKey: this.publicKey });
    }
}
