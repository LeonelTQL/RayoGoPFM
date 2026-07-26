import http from 'k6/http';
import { check } from 'k6';

const baseUrl = __ENV.BASE_URL || 'http://localhost:4000';

export const options = {
  stages: [
    { duration: '15s', target: 25 },
    { duration: '15s', target: 75 },
    { duration: '15s', target: 150 },
    { duration: '15s', target: 0 }
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1200']
  }
};

export default function () {
  const response = http.get(`${baseUrl}/health`);
  check(response, { 'service remains available': (result) => result.status === 200 });
}
