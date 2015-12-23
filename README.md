# cocoadocs-api
This is more of an API _for_ CocoaDocs than the other way around.

### What is this?

The CocoaDocs API is a conduit between CocoaDocs the hosted Mac-Mini that generates a lot of the metadata around a CocoaPod release, and CocoaPods Trunk.

Within that scope has three major roles:

* Take CocoaDocs data and move it into the trunk database ( thereby making it available as an API)
* Perform the CocoaPods Quality Indexes with the data sent from CocoaDocs.
* Tweet out awesome Pods, via @CremeDeLaPods

It uses token based authentication with the CocoaDocs server to ensure anyone can't submit their own data..

It has three API routes:

* `get '/''` -> Says Hello, so you know all is good.
* `post '/pods/:name'` -> Submits JSON data + token from CocoaDocs for parsing and moving into the db.
* `get '/pods/:name/stats'` -> Returns a JSON array of the QIs that apply to a Pod. This is so we can build user interfaces like the one seen on CocoaPods.org.

As QIs are changed, they can be updated by `rake update_all_qis`.
