# About FlowLink

[FlowLink](http://flowlink.io/) allows you to connect to your own custom integrations.
Feel free to modify the source code and host your own version of the integration
or better yet, help to make the official integration better by submitting a pull request!

This integration is 100% open source an licensed under the terms of the New BSD License.

![FlowLink Logo](http://flowlink.io/wp-content/uploads/logo-1.png)


## Developer Environment Setup
Perform the following commands to setup your development environment:

```sh
$ docker rm -f magento-integration-container
$ docker build -t magento-integration .
$ docker run -t -e VIRTUAL_HOST=magento_integration.flowlink.io -e RAILS_ENV=development -v $PWD:/app -p 3000:5000 --name magento-integration-container magento-integration
```

OR

```bash
docker-compose up
```

Then access the local integration at http://localhost:3001

## Connection Parameters

The following parameters must be setup within [FlowLink](http://flowlink.io/):

| Name | Value |
| :----| :-----|
| store_url | URL of your store |
| api_username | API Access Key (required) |
| api_key | API Access Secret (required) |

### Possible Config Options
* __since__ => Used on the GET_ORDERS workflow
* __store_url__ => Used on ALL workflows
* __api_username__ => Used on ALL workflows
* __api_key__ => Used on ALL workflows
* __create_shipment__ => Used on the GET_ORDERS workflow. Should be 0 or 1
