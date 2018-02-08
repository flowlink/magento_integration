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
$ docker run -t -e VIRTUAL_HOST=magento_integration.flowlink.io -e RAILS_ENV=development -v $PWD:/app -p 3001:5000 --name magento-integration-container magento-integration
```

Then access the local integration at http://localhost:3001
