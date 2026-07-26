import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.BASE_URL || 'http://localhost:4000';

export const options = {
  stages: [
    { duration: '10s', target: 10 },
    { duration: '20s', target: 10 },
    { duration: '10s', target: 0 }
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<750', 'p(99)<1500'],
    checks: ['rate>0.99']
  }
};

export default function () {
  const responses = http.batch([
    ['GET', `${baseUrl}/api/products`, null],
    ['GET', `${baseUrl}/api/categories`, null]
  ]);
  check(responses, {
    'all reads succeed': (items) => items.every((item) => item.status === 200)
  });
  sleep(1);
}
