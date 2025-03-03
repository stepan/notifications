create table organizations (
    id serial primary key,
    name varchar(255) not null,
    description varchar(255) not null,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table users (
    id serial primary key,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    email varchar(255) not null,
    password varchar(255) not null,
    organization_id int not null,
    foreign key (organization_id) references organizations(id)

);

create table user_preferences (
    id serial primary key,
    user_id int not null,
    notification_type varchar(255) not null,
    in_app_notifications boolean not null,
    email_notifications boolean not null,
    foreign key (user_id) references users(id)
);

create table notification_types (
    id serial primary key,
    name varchar(255) not null,
    in_app_template text not null,
    email_subject_template text not null,
    email_body_template text not null, 
    in_app_group_debounce_duration int not null,
    email_group_debounce_duration int not null
);

create table batch_notifications (
    id serial primary key,
    notification_id int not null,
    foreign key (notification_id) references raw_notifications(id),
    created_at timestamp not null default now(),
    user_notifications_created_at timestamp 
);

create table raw_notifications (
    id serial primary key,
    triggered_by_user_id int not null,
    notification_type_id int not null,
    notification_data jsonb not null,
    in_app_group_key varchar(255) not null,
    email_group_key varchar(255) not null,
    created_at timestamp not null default now(),
    foreign key (triggered_by_user_id) references users(id),
    foreign key (notification_type_id) references notification_types(id)
);

create table user_in_app_notifications (
    id serial primary key,
    user_id int not null,
    notification_id int not null,
    seen_at timestamp,
    read_at timestamp,
    foreign key (user_id) references users(id),
    foreign key (notification_id) references raw_notifications(id)
);

create table user_email_notifications (
    id serial primary key,
    user_id int not null,
    notification_id int not null,
    foreign key (user_id) references users(id),
    foreign key (notification_id) references raw_notifications(id)
);