// Built from the Terraform AWS provider by the Pulumi bridge, like `local` was.
import * as aws from "@pulumi/aws";

// A real cloud resource that is easy to change behind the tool's back: edit a tag in the S3 console.
// The name is auto-generated: "pulumi-state-refresh-" + 7 random characters.
const bucket = new aws.s3.Bucket("pulumi-state-refresh", {
    forceDestroy: true,
    tags: {
        demo: "tf-vs-pulumi",
        env: "dev",
    },
});

export const bucketName = bucket.bucket;
