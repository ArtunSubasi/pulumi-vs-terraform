import * as random from "@pulumi/random";

const server = new random.RandomPet("server", {
    length: 2,
});

export const serverName = server.id;
