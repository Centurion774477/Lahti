# Lahti

I think JavaScript is a beautiful language. It has a solid blend of speed, flexibility, and strictness; I see a lot of similarities in it to Perl, but I wanted to make it a bit better in CLIs, because currently it is a huge pain to do things like getting inputs, file manipulation, etc. Even printing something to the terminal seems like an afterthought with console.log(). Allow me to introduce you to Lahti (LazyScript).

LazyScript is focused around making JavaScript better for CLI’s, since JS has amazing features like native JSON support (parse and stringify in two words), an excellent async model, and an extremely rich package library.

Therefore, LazyScript doesn’t focus on things like the DOM or HTTP requests; rather, it focuses on things you do most when making CLI tools: REPL. Read: get an input; Evaluate: perform your logic on the input; Print: print something to the console (error, result, etc.); Loop: get ready for the next command.

All of this clarification being said, you should know, before going any further, that LazyScript isn’t meant, in any way, to replace JavaScript, CoffeeScript, or LiveScript. LazyScript isn’t meant for web use at all – it is purely an exploration into just how good JavaScript can become for CLIs when you add a couple of features to it.

I kept the curly braces and dropped the semicolons from JavaScript, however, I did enforce the Perl mindset where curly braces are used for heavier blocks, and lighter blocks are available like inline conditionals, iteration, etc. I feel like this is the best balance because curly braces add enough readability, but having inline escape routes make it so you aren’t in shackles.

# Syntax

Quick comment: the esoteric variable names and values you will see throughout this demonstration are sourced from a variety of songs from some of my favorite bands such as HIM. I just wanted to show that there was some reason behind the weird values.

If a feature is omitted, assume that it is a work in progress, unless I explicitly mention something like "LazyScript is intentionally omitting this feature".


Before we can get into the special CLI features, you must know the basic syntax. 

The syntax of LazyScript was mostly inspired by JavaScript, but also my linguistic/semantics based mindset and a bit of Ruby, Perl, CoffeeScript, and LiveScript, and a taste of Erlang.

## Variable Creation

Use ‘let’ like normal JS to create mutable variables. Alternatively, you can use the ‘my’ keyword as an alias.

`my poisonGirl = “Nemo”`

To create a constant, use constant – not const:

`constant variable = “foobar”`

Alternatively, you can use ‘always’ after declaring:

`variable = “foobar” always`

This is the same thing as using constant.

## Functions

Functions are not yet implemented in Lahti. I will work to implement them shortly, but for now, Lahti is purely procedural.

## Printing

Use speak to print something:

`speak “She's standing on an overpass”`

speak compiles to:

`console.log(“foobar”);`

## Conditionals

Like I said earlier, I designed LazyScript to have light versions and heavy versions of most things. That applies to conditionals. Here’s a “heavy” conditional:

```
if (exampleDictionary.includes(“Hamachi”)) then {
    speak “found Hamachi!”
}
```

Note the 'then' in between the parens and curly brackets. I feel like it removes some of the tension compared to a version that cuts straight to curly brackets.

This compiles to the same thing but without the “then”.

Here are the lighter versions:

By the way, I’m keeping the dreaded === from JS because it has some charm to it.

`if thisLifeJustAintWorthLiving then speak “Join me in death”`

This is just like Ruby's conditionals. It compiles to the multiline version with curly brackets, much like the other inline conditionals. I am aware that JS has inline conditionals, but they aren't very clean.

`say “Join me in death” assuming thisLifeJustAintWorthLiving`

This is like a reverse and statement from Perl; if thisLifeJustAintWorthLiving evaluates to true, then this will output “Join me in death”. 
This also has an alias “granted”:

`drownInYourLove granted youOpenYourArms;`

The good old unless:

`speak “You never left me” unless youLeftMe`

Reverse conditional:

`sleepwalkPastHope if allIsLostInThisWar`


## Loops

LazyScript will have 5 loops: While, Until/Before, Foreach, for, and loop. 

These are just the heavy loops, however. The lighter loop options will be discussed shortly.

### While

```
while (freshOutOfBatteries) do {
    makeNoise
}
```

Note that in every loop you need the ‘do’ between the parens and curly brackets.

This compiles to the same thing, but without the ‘do’.


### Until/Before

This is a reverse while loop; it is saying “do this while this is false”, compared to while loops doing something while something is true.

```
until (foo) do {
    speak “bar”
}
```

You can also replace until with before:

```
before (foo) do {
    speak “bar”
}
```

This compiles to:

```
while (!foo) {
    speak “bar”
}
```

### Foreach
This was already briefly mentioned in the arrays section, but it would be weird to not include it here. This is basically the same as JS:

```
array.each do {
    speak “bar”
}
```

If you want to declare some variables to use in the following block, reference them between each and do:

```
array.each value do {
    speak value;
}
```

Either way, this compiles to:

```
array.forEach(value => {
console.log(value)
});
```

### For

I really don’t like the C-style for loops, so I moved to a Ruby-inspired one.
Here’s how it looks:

```
for 3 times do {
    speak “foo”;
}
```

This compiles to:

```
for (let i = 0, i < 4, i++) {
    console.log(“foo”);
}
```

### Loop
This mainly serves to have an infinite loop for REPLs, so you don’t have to write the dreaded “while (true) {...}”.

Here’s how it looks:

```
loop {
  …
}
```

Right now, there is only one inline loop:

`expression foreach array;`

This compiles to:

`array.forEach(v => expression(v));`

## Either

Either is a shorthand for checking if something is inside of any group. It compiles to a lengthy || statement, not a search using .includes().

Here's an example

```
if (town === either “tampere”, “helsinki”, “kotka”) then {
    speak “Amazing!”
}
```

This compiles to:

```
if (town === “tampere” || town === “helsinki” || town === “kotka”) {
    console.log(“Nice!”);
}
```

To save even more time, there is an alternative keyword named either_string. You can probably guess what this does:

if you write “either_string tampere, helsinki, kotka”, it evaluates the literals as strings, so you don’t have to add quotation marks for each argument.

Here's an example:

```
if (town === either tampere, helsinki, kotka) then {
    speak "Amazing!"
}
```

## Listen

Listen is used to get an input. However, it does not, and will not, output any message.

You can only trigger a blank listen like this:

`listen`

Or, assign a variable to it:

`let input = listen`

I think this is a better separation between speaking and listening compared to letting the listen keyword output text.


## Conclusion

That's about all of the syntax in this version of LazyScript. However, allow me to give a quick example of how a LazyScript file compiles to JavaScript.

Here is the LazyScript:

```
let userInput = listen
listen

speak "Hello, LazyScript!"

constant greeting = hello
name = world always

if escapeFromHellview fails speak "failed to escape"

if town === either "tampere", "helsinki", "kotka" then {
speak "Nice!"
}

if isAlive then speak "still here"

speak "Join me in death" assuming thisLifeJustAintWorthLiving

sleepwalkPastHope if allIsLostInThisWar

speak "You never left me" unless youLeftMe

while (true) do {
speak "looping forever"
}

until (done) do {
speak "not done yet"
}

loop {
speak "generic loop"
}

```

And now the compiled result:


    import readline from 'node:readline/promises';
    import { stdin as input, stdout as output } from 'node:process';

    const rl = readline.createInterface({ input, output });
    
            const userInput = await rl.question('');
            rl.close();
            
            await rl.question('');
            

            console.log("Hello, LazyScript!");
            

            const greeting = hello;
            
            const name = world;
            

            console.log("failed to escape");
            

            if (town === "tampere" || town === "helsinki" || town === "kotka") {
            
            console.log("Nice!");
            
            }
            

            console.log("still here");
            

            console.log("Join me in death");
            

                if (allIsLostInThisWar) {
                    sleepwalkPastHope;
                }
            

            console.log("You never left me");
            

            while (true) {
            
            console.log("looping forever");
            
            }
            

            while (!done) {
            
            console.log("not done yet");
            
            }
            

            while (true) {
            
            console.log("generic loop");
            
            }
            

Quick note: I am working on fixing the compiler so it puts `rl.close()` on the end of the file instead of immediately after getting the input.

Thanks for reading. If you have any questions, feel free to email me at reeceturner1358@gmail.com.
