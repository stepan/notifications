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

At high level our notification service will have the following components:

1. API servers that will be responsible for consuming the raw notifications from our main application and also showing the current user's in-app notifications.
2. Worker servers that will be responsible for turning raw notifications into batch notifications, figuring out which users should receive them, and sending the email notifications.
3. A postgres database that will be responsible for storing notifications and user preferences.

Our main application will generate raw notifications and pass them to the notification service. 

When a user interacts with the application (e.g., uploading a file, creating a comment), the application inserts a raw notification into a queue table in PostgreSQL, which it fully manages. A worker server within the application processes these notifications in batches and sends them to the notification service.
Here is a pseudo code example of how this would work for uploading a file:

main application api: user uploads a file
```typescript
function calclulateInAppGroupKey(userId: number, board: string) {
    return `${userId}-${board}`;
}

function calclulateEmailGroupKey(board: string) {
    return `${board}`;
}

function userFileAdded(userId: number, board: string) {
    // deal with the logic of the file being added

    // create the raw notification in our application postgres table
    // assume we have access to the database with `db`
    await db.sql`
        INSERT INTO raw_notifications (triggered_by_user_id, notification_type, notification_data, in_app_group_key, email_group_key, created_at)
        VALUES (${userId}, 'asset-added', ${JSON.stringify({ board: board })}, ${calclulateInAppGroupKey(userId, board)}, ${calclulateEmailGroupKey(board)}, ${new Date()})
    `;
}
```

main application worker: process the raw notifications
```typescript
function sendRawNotificationsToNotificationService() {
    // assume we have access to the database with `db`

    // first create a db transaction
    db.transaction(async (tx) => {
        // get the raw notifications from the database that are ready to be sent
        // with select for update skip locked in batches of 1000 with the oldest first
        const rawNotifications = await tx.sql`
        SELECT FOR UPDATE SKIP LOCKED * FROM raw_notifications WHERE in_app_group_key = ${inAppGroupKey} AND email_group_key = ${emailGroupKey} ORDER BY created_at ASC LIMIT 1000
    `;

        // send the raw notifications to the notification service
        
        const formattedNotifications = rawNotifications.map((notification) => {
            return {
                triggeredByUserId: notification.triggered_by_user_id,
                notificationType: notification.notification_type,
                notificationData: notification.notification_data,
                inAppGroupKey: notification.in_app_group_key,
                emailGroupKey: notification.email_group_key,
            }
        });

        // send the formatted notifications to the notification service
        // this will make a request to the notification service's `POST /notifications` endpoint to create a batch notification


        await notificationService.sendRawNotifications(formattedNotifications);

        // delete the raw notifications from the database
        await tx.sql`
            DELETE FROM raw_notifications WHERE id IN (${rawNotifications.map(n => n.id).join(',')})
        `;
    });


}
```

We delegate the groupping of notifcations to the main application as it has context of what the nofications are for and can generate a unique key for each group both for in-app and email.


#### API

The API will have the following endpoints:

1. POST `/notifications` - This endpoint will be used by the main application to create a raw notification.
Example request body:
```json
[
    {
        "triggeredByUserId": 1,
        "notificationType": "asset-added",
        "notificationData": { "board": "123" },
        "inAppGroupKey": "1-123",
        "emailGroupKey": "123"
    },
    {
        "triggeredByUserId": 2,
        "notificationType": "comment-created",
        "notificationData": { "asset": "45" },
        "inAppGroupKey": "1-45",
        "emailGroupKey": "45"
    }
]
```

2. GET `/notifications/in-app` - This endpoint will be used by the current user to get their in-app notifications directly from the web app.

If it's feasible for our main application to provide a JWT for the logged in user then we can use that to authenticate requests to our notifcation service directly without using the main application as a middleman.

#### Creating Notifications
When the user interacts with the main application and 


### Database Schema

Take a look at the schema.sql file for the database schema.
