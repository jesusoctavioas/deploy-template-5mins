# Ruby on Rails

In this sections we collect helpful information for deploying Ruby on Rails applications. 

### Master key

See [Rails documentation](https://edgeguides.rubyonrails.org/security.html#custom-credentials). 

Rails uses master key to decrypt `config/credentials.yml.enc`. Find your master key and set it as CI/CD variable `GL_VAR_RAILS_MASTER_KEY` in GitLab project settings. Otherwise deploy may fail. 

### Database migrations

The command to migrate your database depends on whether you’re using a Docker file or Herokuish.

If you have `Dockerfile` then add next line to `gitlab-ci.yml`:

```yml
variables:
  # executed after every deployment
  DB_MIGRATE: "bundle exec rake db:migrate RAILS_ENV=production"
```

If you don't have a `Dockerfile`, your container is build with herokuish. So database migration command will be different: 

```yml
variables:
    DB_MIGRATE: "/bin/herokuish procfile exec bin/rails db:migrate RAILS_ENV=production"
```

### Production environment

For production environment add next line to `gitlab-ci.yml`:

```yml
variables:
    # Rails env production
    GL_VAR_RAILS_ENV: "production"
```

Make sure you have your assets precompiled or `config.assets.compile = true` in `config/environments/production.rb`.

### Active Storage

See [Rails documentation](https://edgeguides.rubyonrails.org/active_storage_overview.html). 

Set active storage to amazon in `config/environments/production.rb`:

```ruby
config.active_storage.service = :amazon
```

Then update `config/storage.yml` with:

```yml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['AWS_DEFAULT_REGION'] %>
  bucket: <%= ENV['S3_BUCKET'] %>
```

### Redis cache

See [Rails documentation](https://guides.rubyonrails.org/caching_with_rails.html). 

Set cache store to redis in `config/environments/production.rb`:

```ruby
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

### SMTP

See [Rails documentation](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration). 

To use Rails email delivery with provided AWS SES you need to provide smtp settings in `config/environments/production.rb`:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_options = {from: ENV['SMTP_FROM']}
config.action_mailer.smtp_settings = {
  address:              ENV['SMTP_HOST'],
  port:                 587,
  user_name:            ENV['SMTP_USER'],
  password:             ENV['SMTP_PASSWORD'],
  authentication:       'plain',
  enable_starttls_auto: true }
```

