"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.enableCors({ origin: true });
    if (process.env.NODE_ENV !== 'production') {
        app.use((req, _res, next) => {
            console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
            next();
        });
    }
    const port = process.env.PORT ?? 3000;
    await app.listen(port);
    console.log(`Server listening on http://localhost:${port}`);
}
bootstrap();
//# sourceMappingURL=main.js.map