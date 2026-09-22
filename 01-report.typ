#import "template.typ": template

#show: template.with(
  title: "AC51041: DevOps and MicroServices",
  assignment: "System Design Brief",
  abstractTitle: "System Design Brief",
)

#set table(align: (x, y) => left, fill: (x, y) => if y == 0 { rgb("F0F0F0") })
#show table.cell: set text(size: 9pt)

= Introduction

The system proposed in this document is to allow registered customers to search
and book conference rooms in locations around the country. Conference rooms have
a maximum capacity attribute. Locations may have one or more conference rooms.
The booking price is determined by the room's base price attribute, plus an
adjustment based on the temperature forecast for the day (see @tab:temperatures
of @app:temperatures). Bookings are made for a full day.

@sec:architecturalDesign proposes a technology agnostic solution. The technology
stack is discussed in @sec:techStack, with two technical solutions compared for
each component, and one chosen with justification given.

We have not been tasked with implementing log-analysis, and for this assessment
the assumption is made that one will not be required.

#v(1em)

= Architectural Design <sec:architecturalDesign>

#figure(
  rect(image("01-img/c4/level2-agnostic.pdf", width: 100%)),
  caption: [Technology Agnostic Container Diagram (C4 Level 2) #v(2em)]
) <fig:c4Level2Agnostic>

The proposed solution depends on four third-party services to provide
authentication, online payments, email, and weather forecasts, which will all be
mocked. A technology agnostic C4 Level 2 diagram is shown in
@fig:c4Level2Agnostic. For assistance in understanding the system's context, see
@fig:c4SystemContext of @app:c4SystemContext.

Each component is described in @tab:systemComponents of @app:systemComponents.
Asynchronous events, published to and consumed from the _Message Queue_, are
listed in @tab:mqEvents of @app:mqEvents. C4 dynamic diagrams are provided in
@fig:dynamicFirst to @fig:dynamicLast of @app:dynamicDiagrams.

AWS @AWS has been chosen as the cloud computing platform due to its maturity,
flexible pricing structure, excellent documentation, and the availability of
online support. It is also the platform that I am most familiar with.

#pagebreak()

= Technology Stack <sec:techStack>

A comparison of each technology required in our system is provided below. The C4
Level 2 diagram has been updated to reflect these decisions, shown in
@fig:c4Level2Specific of @app:c4Level2Specific. @tab:matrix of @app:matrix
provides a matrix table of the components and the technologies that they use.
Where available, AWS technology has been selected to ensure tight integration.
Serverless is the preferred option, reducing maintenance and costs.

*Relational databases* have been chosen for most of our services. A
well-structured, ACID compliant, relational database ensures data integrity, and
our services can take advantage of the strength and flexibility of SQL's
querying power. Multiple instances of the same service can operate on the same
data concurrently, without risk of interfering with each other.

However, our _Logging Service_ is required to quickly store unstructured, or
semi-structured, data from multiple services. Furthermore, complex queries will
not be required for this service. Data will be short-lived, as old logs will be
removed, and so deletion should be easy. To meet these requirements, a *NoSQL*
database will be chosen for the _Logging Service_.

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*React.js* @React], [*Vue.js* @Vue]),

      [
        - Library with dependence on "community standard" libraries for common
          solutions
        - Uses JSX for HTML generation
        - Very good documentation
      ],
      [
        - Framework bundled with official libraries for common solutions
        - Enforced project structure
        - HTML templates, with conditional rendering, such as `v-if` and `v-for`
        - Excellent documentation with links to quality videos
      ],
      table.cell(colspan: 2, [
        My only exposure to front-end development is  PHP and raw HTML. After
        working through some online tutorials I found the approach that Vue.js
        takes to be more logical. I found the Vue.js documentation easier to
        follow, and it provides a "Playground" to test examples. It also
        provides links to free videos on sites such as
        #link("https://scrimba.com/", "Scrimba") and
        #link("https://vueschool.io/", "Vue School"). *Piastou* @Piastou-2023
        found Vue to provide _"#sym.dots a balanced approach with competitive
        performance, lower memory usage, and effective scalability #sym.dots"_
        while React _"#sym.dots demonstrated efficient performance #sym.dots,
        though it has a tendency to result in performance bottlenecks if it uses
        very complex state management unless appropriately optimized."_ Because
        I have found it easier to learn, and with its "low memory usage, and
        effective scalability", I have opted for Vue.js to develop the Web
        Client.
      ]),
    )
  ],
  caption: [Web Client: Framework]
)

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*HTTP API* @Gateway @Gateway-FAQ @Gateway-choice],
        [*REST API* @Gateway @Gateway-FAQ @Gateway-choice]),

      [
        - Simple forwarding
        - Built-in JWT authoriser
        - No caching
      ],
      [
        - Feature-rich forwarding
        - JWT authorisation using Lambda
        - Caching support
        - More expensive
      ],
      table.cell(colspan: 2, [
        Though HTTP API does not provide caching as REST API does, it is the
        cheaper option and, with fewer features, may be easier to set up. The
        built-in JWT authoriser (without the need of a Lambda) is also an
        advantage to help us manage authorisation. Cloud Map @CloudMap will also
        be required to allow the API Gateway to discover our services.
      ]),
    )
  ],
  caption: [API Gateway]
) <tab:api_gateway>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*MySQL* @MySQL], [*PostgreSQL* @PostgreSQL]),

      [
        - Very widely used
        - Smaller feature-set
        - Widespread community support and online tutorials
      ],
      [
        - Less popular
        - Larger feature-set
        - Advanced data types
      ],
      table.cell(colspan: 2, [
        The majority of our services will benefit from the structured querying
        and data integrity provided by a relational database. I am choosing to
        use PostgreSQL for its advanced data types, including JSON.
      ]),
    )
  ],
  caption: [Services: Relational Database]
) <tab:services_relational_database>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*DocumentDB* @DocumentDB @DocumentDB-guide],
        [*DynamoDB* @DynamoDB @DynamoDB-guide]),

      [
        - Document model
        - MongoDB compatible
        - Access only available to services within the same VPC
        - Priced per second, with a 10-minute minimum
      ],
      [
        - Key-value model
        - Time-to-Live feature to delete old log entries
        - Priced per request
      ],
      table.cell(colspan: 2, [
        A NoSQL database is required for the _Logging Service_ so that we may
        take advantage of its fast write speeds, and store semi-structured data
        from multiple components. However, we have no requirement to implement
        logging analysis, so a document model is considered unnecessary.
        DynamoDB is especially designed for high throughput scenarios such as
        logging, and scales to demand. Its TTL feature will allow old logs to be
        automatically deleted or (with a Lambda) archived, making it, along with
        its low cost, my choice of NoSQL database for the Logging Service.
      ]),
    )
  ],
  caption: [Logging Service: NoSQL Database]
) <tab:logging_nosql_database>

#pagebreak()

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*Go with Gin-Gonic* @Go @Gin],
        [*JavaScript with Node.js* @Node]),

      [
        - Compiled language with static typing
        - Small resource footprint
        - Fast cold-start time
        - Compiler caught syntax and type errors
        - Goroutines offer lightweight concurrency
      ],
      [
        - Interpreted language with dynamic typing
        - Large resource footprint
        - Longer cold-start time
        - Single-threaded, I/O bound
      ],
      table.cell(colspan: 2, [
        Go's small resource footprint, and fast cold start time, will reduce AWS
        costs, and allow faster deployment. While interpreted languages, such as
        JavaScript, can lead to faster initial development time, in larger
        systems this is more than offset by fewer bugs reaching production, and
        easier maintenance, thanks to compiler caught errors. Furthermore,
        according to *Pike* @Pike-2012, one of Go's creators @Cox-2022, Go was
        designed for scalability and fast compilation. I observed fast (near
        instantaneous) compilation times when experimenting with Go myself.
        Though not crucial to our design at present, as most blocking will be
        I/O bound (which Javascript's single thread model handles natively),
        *Lumba* @Lumba-2024 found that Goroutines are, on average, 6.25 times
        faster than a thread-based model.

        Gin-Gonic is a popular Go framework, currently with 86,966 stars on
        GitHub @GitLab-Gin, ensuring plenty of community support. It aims to be
        fast, with low memory usage, and includes JSON request validation.
        *Kuffel* and *Walter* @Kuffel2024 used Gin-Gonic as a reference when
        comparing Node.js frameworks for performance in five different
        scenarios, and found Gin-Gonic to be significantly faster than any of
        the Node.js frameworks, in all scenarios except when a server error
        occurs (which they linked to Go's error handling method).
      ]),
    )
  ],
  caption: [Services: Language & Framework]
) <tab:services_framework>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*Simple Notification Service (SNS)* @SNS @SNS-Guide],
        [*Simple Queue Service (SQS)* @SQS @SQS-Guide]),

      [
        - Push-based pub/sub model
        - No persistence
      ],
      [
        - Pull-based queue
        - Messages stored for up to 14 days
        - Dead letter queue
      ],
      table.cell(colspan: 2, [
        Both options provide us with serverless solutions. The pull-based model
        of SQS suits our system better, as each event type is only consumed by
        one service, and the message persistence guarantees consumption. The
        dead letter queue will help us identify and resolve system errors.
      ]),
    )
  ],
  caption: [Messaging]
) <tab:messaging>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*Elastic Container Service (ECS)* @ECS @ECS-FAQ],
        [*Elastic Kubernetes Service (EKS)* @EKS @EKS-FAQ]),

      [
        - Simplified container management
        - No additional fees
      ],
      [
        - Open source industry standard
        - Cost per hour
      ],
      table.cell(colspan: 2, [
        EKS is an open source industry standard, which would reduce our
        dependence on the AWS ecosystem while retaining tight integration. It
        also allows us to employ Kubernetes software. However, it has an hourly
        charge, whereas ECS is free. ECS is also designed to be simple and to
        integrate well with other AWS products. Therefore I have opted to use
        ECS. This will require the use of Docker @Docker to create the images
        for ECS to run.
      ]),
    )
  ],
  caption: [Container Deployment]
) <tab:container_deployment>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*Elastic Compute Cloud (EC2)* @EC2 @EC2-FAQ],
        [*Fargate* @Fargate @Fargate-FAQ]),

      [
        - Full control over resource
        - Requires manual maintenance (patching etc.)
        - Cost per hour
      ],
      [
        - Fully managed serverless solution
        - Charged according to usage --- no cost per hour
        - Automatic scaling
        - Can scale to zero
      ],
      table.cell(colspan: 2, [
        We have no requirement to manually configure our compute, and so with
        its reduced price, reduced maintenance requirement, and automatic
        scaling, Fargate is the preferred solution.
      ]),
    )
  ],
  caption: [Container Compute]
) <tab:container_compute>

#v(1em)

#figure(
  [
    #table(
      columns: (1fr, 1fr),
      table.header([*Service Connect* @Service-Connect],
        [*VPC Lattice* @VPC-Lattice]),

      [
        - Supports HTTP/HTTPS/TCP
        - Uses friendly DNS names
        - No additional charge
      ],
      [
        - Supports HTTP/HTTPS/TCP/gRPC
        - Allows communication across VPCs and accounts
        - Charged by hour and resources consumed
      ],
      table.cell(colspan: 2, [
        Service Connect is the simpler solution provided by AWS, and has no
        additional charge beyond the resources that it consumes in the container
        task. While Lattice allows communication between VPCs and accounts, we
        have no need for this feature. Therefore the system services will
        communicate using Service Connect, over a REST interface, utilising the
        Cloud Map already used by our API Gateway.
      ]),
    )
  ],
  caption: [Service Communication]
) <tab:service_communication>

#pagebreak()

= CI/CD Pipeline <sec:pipeline>

GitHub @GitHub will be used for source code version control. The pipeline will
use GitHub Actions @GitHubActions @GitHubActionsDocs, and be triggered by an
update to the main branch. A pipeline flowchart is provided in @fig:pipeline of
@app:pipeline.

#v(1em)
*Infrastructure as Code (IaC)*

Provisioning of our compute, running tests, and deploying to live, will be
managed through an IaC. Terraform @Terraform and AWS CloudFormation
@CloudFormation were considered. The former was chosen due to its ease of use
and the agnostic flexibility that it offers both cloud and non-cloud platforms.
Terraform will use OIDC credentials to connect to our AWS account, and use S3
@S3 @S3FAQ to store state files.

#v(1em)
*Registry*

GitHub Packages @GitHubPackagesDocs and AWS Elastic Container Registry @ECR
@ECRGuide were considered for the container registry. Though storing our images
on the same platform as our source code was considered, it was decided that
using ECR would prevent introducing additional authentication complexity.

#v(1em)
*Test Suites*

*UI:* Playwright @Playwright for its popularity and GitHub Action support
@PlaywrightCI.

*Unit & Integration:* Pytest @Pytest for its wide community support and
extensive list of plugins @PytestPlugins.

*Load:* Locust @Locust can be run in headless mode, while periodically saving
results to CSV files. It uses a Python code architecture.

Tests will be run in an AWS test environment, created in a dedicated test VPC. A
notification will be sent to a review team, who will need to manually approve
the code going live.

Docker Compose @DockerCompose will be used for local development and testing, to
ensure consistency with the live environment.

#v(1em)
*Deployment*

A Blue/Green Deployment @BlueGreenDeployments strategy will be used to deploy
the _previously built images_ to the live environment, utilising AWS Code Deploy
@CodeDeploy @CodeDeployGuide. *Pappula* @Pappula-2022 observed that such a
method allows extensive testing of the new environment, and quick rollback if
necessary, at the cost of increased resource costs during deployment. He found
that _"the core metrics #sym.dots improved substantially, with no downtimes and
reduced error rates, by 100% and 80.95%, respectively, and latency in updating
an application was reduced by 20%."_ while *Vangala* @Vangala-2020 found
_"[e]xperimental results indicated Blue-Green Deployment achieved a deployment
success rate of 98.8% and maintained a recovery time of under 1.5 minutes."_

#pagebreak()

#counter(heading).update(0)

#[
#set heading(numbering: "A.1", supplement: [Appendix])
#show heading.where(level: 1): it => block(width: 100%)[
  #v(1em)
  Appendix #counter(heading).display("A"): #it.body
  #v(0.6em)
]

= Temperature Price Adjustments <app:temperatures>

The system requirements state that conference room prices are adjusted by the
temperature forecast for the day of the booking, as shown in @tab:temperatures,
where $T = "temperature"$.

#figure(
  [
    #set table(fill: white)

    #table(
      columns: (1fr, 1fr),

      [$0#sym.degree\C <= T < 2#sym.degree\C$],
      [No additional charge],

      [$2#sym.degree\C <= T < 5#sym.degree\C$],
      [10%],

      [$5#sym.degree\C <= T < 10#sym.degree\C$],
      [20%],

      [$10#sym.degree\C <= T < 20#sym.degree\C$],
      [30%],

      [$20#sym.degree\C <= T$],
      [50%],
    )
  ],
  caption: [Price Adjustments]
) <tab:temperatures>

#v(1em)

= C4 System Context Diagram <app:c4SystemContext>

@fig:c4SystemContext shows the context of the booking system. The proposed
solution depends on four third-party services to provide authentication, online
payments, email, and weather forecasts.

#figure(
  rect(image("01-img/c4/level1.pdf", width: 100%)),
  caption: [System Context Diagram (C4 Level 1)]
) <fig:c4SystemContext>

#pagebreak()

= System Components <app:systemComponents>

@tab:systemComponents lists the eleven main components proposed for the system,
and a brief description of each.

#figure(
  [
    #set table(fill: white)

    #table(
      columns: (25%, 1fr),

      [*Web Client* (presentation)],
      [
        User interface to search and book conference rooms. All requests are
        routed through the _API Gateway_.
      ],

      [*API Gateway* (presentation)],
      [
        Routes requests from the _Web Client_ to the appropriate service, and
        confirms _Web Client_ authorisation.
      ],

      [*Authentication* (business)],
      [
        Provides management of login and registration security details. Creates
        new credentials and publishes a registration event to the _Message
        Queue_.
      ],

      [*Customer* (business)],
      [
        Maintains customer account profiles. Consumes registration events from
        the _Message Queue_ to create new profiles, before publishing a new
        customer event. Provides customer details to the _API Gateway_ and other
        microservices.
      ],

      [*Booking* (business)],
      [
        Stores confirmed and requested bookings. Allows the _API Gateway_ to
        request a conference room booking, and to check existing bookings.
        Consumes payment events, and publishes booking events.
      ],

      [*Room* (business)],
      [
        Maintains descriptions, photos, prices, and capacities, of the
        conference rooms. Uses the _Weather Service_ to retrieve weather
        forecasts, so that a room price may be adjusted according to the
        expected temperature. Provides the _API Gateway_ with a conference room
        search facility. The _Web Client_ must get the booking status from the
        _Booking Service_.
      ],

      [*Email* (support)],
      [
        Consumes new customer and booking events from the _Message Queue_ to
        email customers. Stores email templates in its database.
      ],

      [*Logging* (support)],
      [
        Provides a logging facility to all microservices. Each microservice, and
        the _API Gateway_, has a "Sends application logs to" relationship with
        the _Logging Service_ (not shown in the diagram to maintain clarity).
      ],

      [*Payment* (support)],
      [
        Processes customer payments for the _Booking Service_, using the
        external _Payment Provider_. Returns the result asynchronously via the
        _Message Queue_ by publishing a payment status event.
      ],

      [*Weather* (support)],
      [
        Provides temperature information by location and date. Uses the external
        _Weather Provider_ to retrieve forecasts at regular intervals, and
        caches the response locally to allow synchronous responses to the _Rooms
        Service_.
      ],

      [*Message Queue* (support)],
      [
        Provides asynchronous communication functionality between services.
        Associated data is stored within the event.
      ],
    )
  ],
  caption: [C4 System Components]
) <tab:systemComponents>

#v(1em)

= Message Queue Events <app:mqEvents>

The system publishes and consumes four events to the _Message Queue_, allowing
asynchronous processing, as shown in table @tab:mqEvents.

#figure(
  [
    #set table(fill: white)

    #table(
      columns: (25%, 1fr),

      [*Web Client* (presentation)],
      [
        User interface to search and book conference rooms. All requests are
        routed through the _API Gateway_.
      ],

      [*Registration*],
      [
        Published when new authentication credentials are created. Consumed by
        the _Customer Service_ to create a new customer profile.
      ],

      [*New Customer*],
      [
        Published by the _Customer Service_ after a profile is created. Consumed
        by the _Email Service_ to send a welcome message.
      ],

      [*Payment Status*],
      [
        Published by the _Payment Service_ when a payment transaction completes,
        regardless of success or failure. Consumed by the _Booking Service_ to
        confirm the booking in its database, or to remove it.
      ],

      [*Booking*],
      [
        Published by the _Booking Service_ when a room booking is paid for and
        confirmed. Consumed by the _Email Service_ to send a confirmation and
        receipt to the customer.
      ],
    )
  ],
  caption: [Message Queue Events]
) <tab:mqEvents>

#pagebreak()

= C4 Dynamic Diagrams <app:dynamicDiagrams>

@fig:dynamicFirst to @fig:dynamicLast are C4 dynamic diagrams, illustrating how
the system components collaborate for the four main runtime requests in our
system. Note that to maintain clarity, communication with the _Logging Service_
is not shown.

#v(1em)

#figure(
  rect(image("01-img/c4/dynamic/registration.pdf", width: 100%)),
  caption: [New Customer Registration]
) <fig:dynamicFirst>

#v(3em)

#figure(
  rect(image("01-img/c4/dynamic/authentication.pdf", width: 60%)),
  caption: [Customer Authentication]
)

#figure(
  rect(image("01-img/c4/dynamic/search.pdf", width: 100%)),
  caption: [Room Search]
)

#v(3em)

#figure(
  rect(image("01-img/c4/dynamic/booking.pdf", width: 100%)),
  caption: [Successful Room Booking Request]
) <fig:dynamicLast>

#pagebreak()

= Technology Specific Container Diagram <app:c4Level2Specific>

@fig:c4Level2Specific extends the Level 2 Agnostic diagram
(@fig:c4Level2Agnostic) with the technology stack identified in @sec:techStack.

#figure(
  rect(image("01-img/c4/level2-specific.pdf", width: 100%)),
  caption: [Technology Specific Container Diagram (C4 Level 2)]
) <fig:c4Level2Specific>

= Technology Matrix Table <app:matrix>

@tab:matrix details the relationship between our components identified in
@sec:architecturalDesign, and the technologies identified in @sec:techStack.
Note that the _Messaging_ component is located in the top row, where it becomes
more useful in this context.

A relationship with Gin-Gonic implies a relationship with Go. "S. Connect" is an
abbreviation of "Service Connect".

#figure(
  [
    #let rot(body) = rotate(-60deg, reflow: true, body)

    #set table(
      fill: white,
      align: (x, y) => if y == 0 { bottom + center } else { horizon + left },
      stroke: (x, y) => (top: none, bottom: 0.5pt),
    )

    #table(
      columns: (3fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      table.header([], rot[Vue.js], rot[HTTP API], rot[JWT Authorizer],
        rot[Cloud Map], rot[Gin-Gonic], rot[PostgreSQL], rot[DynamoDB],
        rot[SQS (Messaging)], rot[ECS], rot[Fargate], rot[S. Connect]),

      [*Web Client*],     [●], [ ], [ ], [ ], [ ], [ ], [ ], [ ], [ ], [ ], [ ],
      [*API Gateway*],    [ ], [●], [●], [●], [ ], [ ], [ ], [ ], [ ], [ ], [ ],
      [*Authentication*], [ ], [ ], [ ], [ ], [●], [●], [ ], [●], [●], [●], [●],
      [*Customer*],       [ ], [ ], [ ], [ ], [●], [●], [ ], [●], [●], [●], [●],
      [*Bookings*],       [ ], [ ], [ ], [ ], [●], [●], [ ], [●], [●], [●], [●],
      [*Room*],           [ ], [ ], [ ], [ ], [●], [●], [ ], [ ], [●], [●], [●],
      [*Email*],          [ ], [ ], [ ], [ ], [●], [●], [ ], [●], [●], [●], [●],
      [*Logging*],        [ ], [ ], [ ], [ ], [●], [ ], [●], [ ], [●], [●], [ ],
      [*Payments*],       [ ], [ ], [ ], [ ], [●], [●], [ ], [●], [●], [●], [●],
      [*Weather*],        [ ], [ ], [ ], [ ], [●], [●], [ ], [ ], [●], [●], [●],
    )
  ],
  caption: [Technology Matrix]
) <tab:matrix>

= CI/CD Pipeline Flowchart <app:pipeline>

@fig:pipeline presents a flowchart for our CI/CD pipeline, as described in
@sec:pipeline.

#v(1em)

#figure(
  rect(image("01-img/pipeline.pdf", width: 100%)),
  caption: [CI/CD Pipeline Flowchart]
) <fig:pipeline>
]

#pagebreak()

#bibliography("01-refs.bib", title: "References", style: "ieee")
