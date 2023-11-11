import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
    discardResponseBodies: true,
    scenarios: {
        contacts: {
        executor: 'per-vu-iterations',
        vus: 1,
        maxDuration: '500s',
        },
    },
};

export default function () {
    const res = http.get(`http://${__ENV.host}:${__ENV.port}/function/hello-world`);
    sleep(0.05);
}
