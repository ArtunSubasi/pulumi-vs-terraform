import * as random from "@pulumi/random";
// Built from the Terraform AWS provider by the Pulumi bridge, like `local` was.
import * as aws from "@pulumi/aws";

const db = new random.RandomPassword("db", {
    length: 16,
    special: false,
});

// A real cloud resource that is easy to change behind the tool's back: edit a tag in the S3 console.
// The name is auto-generated: "pulumi-state-refresh-" + 7 random characters.
// LIVE: new aws.s3.Bucket("pulumi-state-refresh", ...) — forceDestroy: true, tags { demo: "tf-vs-pulumi", env: "dev" }

// LIVE: export const bucketName
