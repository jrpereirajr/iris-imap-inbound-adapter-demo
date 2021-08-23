# iris-imap-inbound-adapter-demo
A simple implementation of IMAP protocol as an IRIS Interoperability Inbound Adapter

## What The Sample Does
This sample presents an interoperability production which is composed by a [business service]() and a [business operation](). The business service uses the [IMAP inbound adapter](https://github.com/jrpereirajr/iris-imap-inbound-adapter-demo/blob/10a0e80ff7d3d7fe80b6447e682f541d380db4a3/src/dc/Demo/IMAPInboundAdapter.cls#L2) to check for new messages every 10 seconds. Such adapter relies on an simple [IMAP client](https://github.com/jrpereirajr/iris-imap-inbound-adapter-demo/blob/10a0e80ff7d3d7fe80b6447e682f541d380db4a3/src/dc/Demo/IMAP.cls#L4) implementation. This code was inspired by the [Demo.Loan.FindRateProduction](https://docs.intersystems.com/latest/csp/documatic/%25CSP.Documatic.cls?&LIBRARY=ENSDEMO&PRIVATE=1&CLASSNAME=Demo.Loan.FindRateProduction) interoperability sample.

In short, this production:
 - Uses the GetMessageUIDArray method to get all available messages in the configured mailbox
 - Loop over them tracing their output - fetched by Fetch method
 - Check if each message subject match to a criteria - start by "[IMAP test]"
 - If message subject matches the criteria, a response is sent back to the sender; otherwise, the message is ignored
 - Delete all of them in the end - so they won’t be analysed again.

In this example an IMAP server from Yahoo Mail was configured - imap.mail.yahoo.com, on port 993. The default IRIS SSL configuration ISC.FeatureTacker.SSL.Config was used.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/foc7gpuAKH.png)

A SMTP server was configured as weel, in order to receive acknolodge messages in response to messages grabbed through IMAP. As for IMAP, Yahoo Mail was used for SMTP - smtp.mail.yahoo.com, port 465. Please, onfigure one recipient in "Recipient" field.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/SAT6RbWBzl.png)

Note that user and password were stored in a credential called imap-test.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/brY9RdilYO.png)

As you can see in the image below, the production starts and keeps querying the IMAP server for new messages. When there’re new messages, the inbound adapter grabs their information - like from header and subject, and lets production be able to take further actions based on such information.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/mocptwDsOd.png)

The action taken in this example was to check if the message subject starts with "[IMAP test]" and send back a message to the sender.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/vUyVCCBQjr.png)

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/xYeUVatYSA.png)

When a message doesn’t match the criteria, it is just ignored by production.

![](https://raw.githubusercontent.com/jrpereirajr/iris-imap-inbound-adapter-demo/master/img/tvG4umHC0T.png)

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation: ZPM
Coming soon...

## Installation: Docker
Clone/git pull the repo into any local directory

```
$ git clone https://github.com/intersystems-community/iris-imap-inbound-adapter-demo.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Run the Sample
Set [dc.Demo.imap.IMAPTestService](https://github.com/jrpereirajr/iris-imap-inbound-adapter-demo/blob/master/src/dc/Demo/imap/IMAPTestService.cls) and [dc.Demo.imap.IMAPTestSendEmailOperation](https://github.com/jrpereirajr/iris-imap-inbound-adapter-demo/blob/master/src/dc/Demo/imap/IMAPTestSendEmailOperation.cls) parameters, configure credentials with user/password to your IMAP and SMTP server and naming it as imap-test, like explained [above](https://github.com/jrpereirajr/iris-imap-inbound-adapter-demo#what-the-sample-does). Then open the [production](http://localhost:52785/csp/irisapp/EnsPortal.ProductionConfig.zen?PRODUCTION=dc.Demo.imap.Production) and start it.
A few secondes later you should start to see trace information with information on grabbed messages from the server in the [Event Log](http://localhost:52785/csp/irisapp/EnsPortal.EventLog.zen) page.