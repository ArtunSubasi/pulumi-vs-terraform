import * as pulumi from "@pulumi/pulumi";
import { describe, expect, it } from "vitest";
import { Service } from "./service";

// Mocks replace the engine and every provider: no plugins, no state, milliseconds per test.
// (service.ts only defines a class. A module that creates resources at import time
// would have to be imported after setMocks, e.g. with a dynamic import.)
pulumi.runtime.setMocks({
    newResource: (args) => {
        const state = { ...args.inputs };
        if (args.type === "random:index/randomPassword:RandomPassword") {
            state.result = "fixed-for-test";
        }
        return { id: `${args.name}-id`, state };
    },
    call: (args) => args.inputs,
}, "testing", "test", false);

// Unwrap an Output<T> in a test (secrets included)
const valueOf = <T>(output: pulumi.Output<T>) => new Promise<T>(resolve => output.apply(resolve));

describe("Service", () => {
    it("writes name and port into the config", async () => {
        const svc = new Service("billing", { port: 9000 });
        const config = JSON.parse(await valueOf(svc.config));
        expect(config).toMatchObject({ service: "billing", port: 9000 });
        expect(await valueOf(svc.configFile)).toBe("out/billing.json");
    });

    it("builds the connection string from the generated password", async () => {
        const svc = new Service("api", { port: 8080 });
        expect(await valueOf(svc.connectionString))
            .toBe("postgres://api:fixed-for-test@db.internal:5432/api");
    });

    it("rejects privileged ports", () => {
        expect(() => new Service("web", { port: 80 })).toThrow(/1024/);
    });

    // LIVE: it("rejects uppercase names") — new Service("Billing", ...) throws /lowercase/
});
