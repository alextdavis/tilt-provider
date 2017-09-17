# Tilt-Provider

> Render views for your Vapor server with Tilt

This project is a View Provider for the [Vapor](https://vapor.codes) framework
which uses the Ruby library [tilt](https://github.com/rtomayko/tilt) to render
views. This allows the use of a plethora of templating languages, including
ERB, Haml, Sass, Markdown, CoffeeScript, and TypeScript to name a few.

### Why?

The major motivation for this project is so that developers with prior
experience in Ruby web development can start using Vapor while continuing to use
the templating engine they're familiar with, or that projects being ported from
Ruby frameworks to Vapor can continue to use existing template code.

Even for those without experience with Ruby, there are uses. The Leaf templating
language has limited programming capabilities by design. Some applications might
benefit from being able to inject a full language. And, templating languages
like [Haml](http://haml.info) have unique advantages of their own.

### How it works

This provider has three parts. One part is a Swift Package which interfaces with
Vapor. The second part is a Ruby Gem,
[vapor_tilt_adapter](https://github.com/alextdavis/vapor-tilt-adapter), which
processes the data from Vapor and renders the view. The final part is a single
file Ruby script which you write which serves as the glue to join the Vapor and
Ruby parts.

When you call `view.make` from your Vapor controller, you pass in a dictionary
which gets encoded as a JSON object. This contains all the data you want to make
available to the view (similar to how Leaf works). The provider then passes all
the necessary information to a Ruby script which exposes the data described in
the JSON object to the views, renders the view, and stores it to a temporary
file. The provider then reads the temporary file, deletes it, and returns the
rendered view.

## Installation

With all the different parts of this project, how to get started takes some
explaining.

### Requirements

- Vapor 2
- Ruby 2.3+ (Versions of macOS before 10.13 High Sierra ship with a version of
  Ruby which is too old. Only Macs with 10.13 or newer can use the system Ruby.)
- The Ruby gem
  [vapor_tilt_adapter](https://github.com/alextdavis/vapor-tilt-adapter)

### Swift Side

Add this line to the `dependencies` array in your Package.swift:

```swift
.Package(url: "https://github.com/alextdavis/tilt-provider.git", majorVersion: 0),
```

Then, edit `config/droplet.json` so that the view field reads "tilt":

```swift
"view": "tilt",
```

### Ruby Side

If you're a Rubyist, I'll assume you already have an installation using
[RVM](https://rvm.io), which is a great tool to manage multiple Ruby
versions/environments.

Otherwise, if you want something to just work, on Ubuntu, use:

    $ sudo apt install ruby

Or on Mac version 10.12 Sierra and lower, use: (as mentioned earlier, on macOS
10.13 High Sierra or above, the built-in Ruby will suffice.)

    $ brew install ruby

Ensure you're using the version of Ruby you just installed with:

    $ ruby -v

Which should be something >= 2.3.0.

Then you'll need to install the gem:

    $ gem install vapor_tilt_adapter

If you want to use certain template languages, like Haml, you may need to
install gems for those individually. See the table at
[the Tilt readme](https://github.com/rtomayko/tilt) for more info.

### Adapter

Now you're ready to create the adapter script. This needs to be named
`adapter.rb`, and be placed in the views directory of your vapor project
(typically this would be `Resources/Views/adapter.rb`). Here's a sample file:

```ruby
#!/usr/bin/env ruby
require 'vapor_tilt_adapter'

view_dir          = ARGV[0]
template_filename = ARGV[1]
output_path       = ARGV[2]
context           = STDIN.read

class MyRenderer < VaporTiltAdapter::Renderer

  # define any helper methods here. I included this as an example:
  def partial(template_name)
    template_name = template_name.to_s + ".haml" if template_name.is_a? Symbol
    Tilt.new(VIEW_DIR + template_name).render(self)
  end
end

MyRenderer.new.render(view_dir, template_filename, output_path, context)

```

The `view_dir`, `template_filename`, and `output_path`, come through as command
line arguments. The `context`, the JSON string which carries any data from Swift
to Ruby, is piped in via the Standard Input. You have the option to manipulate
these values if you'd like, but you shouldn't need to.

Defining your own subclass of `VaporTiltAdapter::Renderer` is your opportunity
to customize the behavior of the renderer.

Once you create your adapter script, make sure that the Vapor process has
execute access to it.

## Usage

In your controller, a view make call should look like this:

```swift
return try self.view.make("home.haml",
                          ["layout": "layout.haml",
                           "@user": user.makeJSON(),
                           "@foo": self.foo,
                           "@bar": baz.bar)
                          ])
```

The first argument is simply the name of the template. The second is of type
Node, containing a Dictionary with String keys and Node values. Keys with an
"@" symbol as the first letter will be exposed in the template as an instance
variable. So to access the return of `user.makeJSON()` from the template, use
`@user`. Keys without "@" symbols are used internally by vapor_tilt_adapter, and
currently there's only the one, `layout`, which can be used to specify a layout
template, or omitted to use the default (which is set with an optional argument
to `VaporTiltAdapter::Renderer#render`).

## Development

The only thing of note is that if you're using CLion as an IDE, I wrote a script
which generates a CMakeLists.txt automatically, which includes all of the
dependencies' sources, so the IDE indexes them.
Make sure you've updated your dependencies with `vapor update`, and and then run
`ruby Script/clion.rb`.

## Limitations

If you need to make a lot of data available to Ruby, be wary of the poor
performance of Fluent models' `makeJSON()` method. In my project, trying to load
a page with an HTML table of a few thousand rows from a Postgres database was
taking several seconds. I discovered that most of that time was being spent
in the `makeJSON()` call, and everything after the JSON strings were generated
was only taking a few hundred milliseconds. Now, I'm using custom queries which
take advantage of Postgres's JOSN functions, and overall performance is quite
acceptable.

Currently, every time a view is rendered, a new Ruby process is spawned, and the
templates are interpreted from scratch. It would be more efficient to keep one
Ruby process around, and take advantage of Tilt's caching capabilities. Static
pages could also be cached in Swift.

## Contributing

This project is in its infancy, and any contributions are very welcome.
In particular, any input from the Vapor team on how to better integrate or
improve this software vis-à-vis it being a Vapor provider would be greatly
appreciated.

The biggest thing left to do before this project can be used in any sort of
production environment is that we need to have tests. Anyone willing to work
on writing tests should feel free to get in touch with project maintainers with
questions.

Bug reports and pull requests are welcome on GitHub at
https://github.com/alextdavis/tilt-provider. This project is intended to be
a safe, welcoming space for collaboration, and contributors are expected to
adhere to the Contributor Covenant code of conduct.

## Maintainers

This project's creator and maintainer is Alex T. Davis (git@alextdavis.me).

## License

The software is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT)

## Code of Conduct

Everyone interacting in the tilt-provider project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/alextdavis/tilt-provider/blob/master/CODE_OF_CONDUCT.md).
