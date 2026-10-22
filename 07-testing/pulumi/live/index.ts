import { Service } from "./service";

const api = new Service("api", { port: 8080 });

export const configFile = api.configFile;
export const connectionString = api.connectionString;
