# Contract Testing with Pact

## Consumer Side (Order Creation)
```javascript
const { Pact } = require('@pact-foundation/pact');
const provider = new Pact({
  consumer: 'processor',
  provider: 'orders',
  port: 1234,
});

beforeAll(() => provider.setup());

describe('POST /v1/orders', () => {
  beforeEach(() => provider.addInteraction({
    state: 'a valid request',
    uponReceiving: 'a record creation',
    withRequest: {
      method: 'POST',
      path: '/v1/orders',
      body: { value: 1000, category: 'standard' }
    },
    willRespondWith: {
      status: 201,
      body: { id: 'shp_123', status: 'label_created' }
    }
  }));
  // test...
  afterEach(() => provider.verify());
});
```

## Provider Verification
```bash
pact-verifier --provider-base-url=http://localhost:8080 \
  --pact-url=./pacts/processor-records.json
```
