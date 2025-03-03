## Notification System Technical Documentation

### Approaches
There are two main ways we could incorporate notifications into our application.

1. We could include the notifcation code and logic within our main application codebase.
2. We could create a separate service that is responsible for consuming and sending notifications.

#### Option 1: Within the main application
This option would be the simplest way to implement notifications since we would just need to write our notifcation logic and then could share all other resources such as the infrastructure and database.
The downside of this approch is that it would be much more difficult to scale since we would be constrained by the resources of our main application.

#### Option 2: Notification Service
Spinning up a new service would allow us to scale the notification service independently of our main application since we can more easily scale out our web and worker resources and the database.

The drawback of this approach is that now we would be responsible for maintaing yet another service and have to worry about things such as database migrations, deployment, and monitoring and what happens if this service goes down.

Based on the product specs given I suggest going with option 2 as it provides the best way to scale and manage notifications in the long run without potential slowdowns in the main application.


### Architecture
![Diagram](diagram.jpg "Diagram")




### Database Schema

Take a look at the schema.sql file for the database schema.