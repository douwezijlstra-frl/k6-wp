# k6

Original repo: https://github.com/cachewerk/k6 


## Setup

Make sure [k6 is installed](https://k6.io/docs/getting-started/installation/).

All tests can be run locally using `k6 run` or in the cloud using `k6 cloud`. 

When Object Cache Pro is installed, custom metrics for [WordPress, Redis and Relay](lib/metrics.js) are automatically collected. 

## Bulkbench
The bulkbench script is a script to simplify running multiple tests in a row. It will run the specified test with 10, 25 and 50 virtual users, and output the results to a file in the `results` directory.

To use the bulkbench script, you need to provide the following command line arguments:

- `-d <site_url>`: The URL of the site you want to test.
- `-n <num_runs>`: The number of times you want to run each test. This is useful if you want to make changes after each run and see how they affect the results.
- `-t <k6_testfile>`: The path to the k6 test file.

Here's an example of how to use the bulkbench script:

```
./bulkbench.sh -d https://example.com -n 5 -t tests/my_test.js
```

## Tests

### `wp.js`

Fetches all WordPress sitemaps and requests random URLs.

```
k6 run wp.js --env SITE_URL=https://example.com
k6 run wp.js --vus=100 --duration=10m --env SITE_URL=https://example.com
```

### `woo-checkout.js`

Loads the homepage, selects and loads a random category, selects a random product and adds it to the cart, loads the cart page and then places an order.

```
wp option update woocommerce_enable_guest_checkout no --autoload=no
wp option update woocommerce_enable_signup_and_login_from_checkout yes --autoload=no

k6 run woo-checkout.js --env SITE_URL=https://example.com
```

Be sure to [reset WooCommerce](#reset-woocommerce) between test runs.

### `woo-customer.js`

Loads the homepage, signs in, views at orders and then their account details.

```
k6 run woo-customer.js --env SITE_URL=https://example.com
```

This script requires [seeded users](#seeding-users).

## Environment variables

### Site URL

You can pass in the `SITE_URL` to point the traffic at at specific URL.

```
k6 run wp.js --env SITE_URL=https://example.com
```

### Project ID

You can set the k6 Cloud "Project ID" using the `PROJECT_ID` environment variable.

```
k6 cloud wp.js --env PROJECT_ID=123456 --env SITE_URL=https://example.com
```

### Bypass page caches

To attempt bypassing page caches without logging in, pass in `BYPASS_CACHE`:

```
k6 run wp.js --env BYPASS_CACHE=1
```

## Reset WooCommerce

```
wp post delete --force $(wp post list --post_type=shop_order --format=ids --posts_per_page=-1)
wp user delete --yes $(wp user list --role=customer --format=ids --posts_per_page=-1)
wp cache flush
```

## Seeding users

Load tests that run with logged in users, use this seed command to create 100 users:

```
for USR_NO in {1..100}; do wp user create "test${USR_NO}" "test${USR_NO}@example.com" --role=subscriber --user_pass=3405691582; done;
```
