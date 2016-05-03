    Cesar Quiroz
    2016-03-07



DRAFT FOR LAWRENCE'S EYES ONLY



# Executive Summary

This is a review of the build system task I commissioned in late September
2015, evaluated as of early March 2016. It covers my understanding of the
achievements and shortcomings of the offered deliverables, and some lessons
learned. It concludes with my expectations of how we will move
forward. Factual corrections and other feedback are very welcome.

My assessment of the task *at* *this* *point* is that the main goals were
met, at least partially (see below)--we could work from that basis on.
However, the
proffered deliverables reach beyond the scope of the instrumental changes
required, to changing the architecture and the developer's UI of the build
system--the new system, aside its real merits, is a regression from the one we
had before, as we lost functionality we had, without compensation.

My diagnostic is that my informal statement of the original requirements is to
blame for inviting a serious excursion; I am disappointed in myself for not
writing a document like this at the beginning. I am also disappointed that the
_consequences_ of the massive changes implemented were not modeled and
discussed in review, and I am disappointed that my concerns have been ignored
in the implementation, in spite of having raised them early and often. 

I can't help but observe that tiring me into accepting an imposition that
harms innergy will not work. I am still responsible for leading our
Engineering efforts. I own the consequences of delegating this task.

The customer is the only judge of the quality of the product; if the customer
rejects a change and cannot be convinced otherwise, the correct thing to do is
to implement what the customer wants, and perhaps make a proposal to extend
the original scope later. In this task, I am the customer, and I have not
accepted the deliverable. I have reviewed the justifications, and I am not
convinced that all of this was needed to accomplish the objective. If we get
to that, it is my call, and it is no.


# Background

The task under review was designed to welcome Lawrence to our source
code. Thus, it addressed problems that were not urgent, but could eventually
become urgent. The actual deliverable (expected to be very light) was less
important than enabling Lawrence to examine the code and use the demo
software.

Naturally, it was expected that this would lead to his proposing deeper
changes for productivity and quality, and that was mentioned in
conversation. We study something, then we improve on it. Conversely, we can't
pretend to improve what we don't understand. I was looking forward
to thoughtful proposals. I didn't expect to be blindsided.


## Technical deliverables

Two weaknesses of our environment at the time were that (1) the build system
built on-tree, (2) we had no regression testing framework. Worse, of course,
we had no tests of any scale: unit, functional, regression, performance. 


Therefore, the two deliverables I requested were:

D1. Modify the build system to enable off-tree builds.

D2. Evaluate a regression testing scheme.

D0. Implicit in all requirements is the one to do no harm: I expect
that the above deliverables can be produced without losing existing
functionality, or that unavoidable tradeoffs will be presented for my choice
with a cost-benefit analysis.


## Criticism of the informal specification

I failed to write down in detail all the requirements and relevant business
constraints, in the wishful thought that Lawrence and I would shape together
this mini-project.

--- Please understand that I did write down all the requirements known
to me.  They were in the design document that I circulated.

The objective D1 is actually ambiguous in two ways: 

  *  Did I mean the developer's build system, or some other build system (the
release management build system, the continuous integration build
system...). 

  *  What did I mean by "off tree". 
  
The objective D2 is open-ended. On the other hand, we had nothing, so a
narrowing of choices had to be a win, at some price.

  
### What build system?

I had in mind the developer's build system, the only one we had at the
time. The one I and others use a dozen times a day. Perhaps circumscribing the
task to that goal would have kept it focused.

--- You persistently seem to miss the point that the makefiles that I
delivered were two build systems.  An 'ecosystem' build and a developer
build.  Since the latter is called by the former, asking folks to test
the former was sufficient for validating both.

It was possible to interpret this requirement in the sense of unattended
builds, as Release Management would need eventually. I have come to accept
that automated builds need to run on pre-configured machines--good, but 
irrelevant to the developer's system.

--- Not irrelevant, but not something one deals with often.

If our old build system had been studied before committing to changing it, it
would have been discovered that

  * Our makefiles built our product correctly (in the clean and the
    incremental senses),

  * --- Done.
    
  * Our makefiles confined the Verific makefiles, but did not try to replace
    them. There are good reasons for this: we are still using an eval, not
    their product, and we don't control when that will change.

  * --- The same is true of my build.
    
  * Our makefiles observed the custom that `make` invoked at the top built the
    entire product (but not the externals).

  * --- So here we diverge.  I have seen enough people doing unconventional
    things that being explicit reduces errors.  Even so, I have up that check.
    
  * Our makefiles supported an extensive range of source navigation tagging
    mechanisms: EDE, Exuberant Ctags, Emacs Ctags, GNU Global, CScope. That
    had required at some removing symbolic links from the repo and build areas
    (those links were a crude file sharing mechanism), to
    avoid limitations like not being able to decide which of two identically
    named files is the right one to jump to.

  * --- Adding the tagging should not be a big deal.  It has been on the
    plan, but behind ensuring that the build is functional.  You agreed to
    that plan.
    
  * Builds made by our tools supported the GNU debugging tools and profilign
    correctly. The DWARF information pointed back to repo-based sources, not
    to build artifacts.

  * --- And I agreed to switch to a vpath specification after we had
    stabilized the build.  You agreed to that plan.
    
We'll see below that all of these features of the old system were broken by the
new one, with no value compensating for that unapproved cost.

--- There is substantial value, and if you would ask, I would tell you.
Just because you did not invoke


### What is Off-Tree Building?

The minimal requirement (not to write back to the sources during the build)
has been accomplished. This is a reasonable interpretation of building
off-tree. I consider this an acceptable partial deliverable.

I should have pointed out the build systems of the Linux Kernel and GNU Emacs
as examples of what I wanted: a build system that lets me designate an
ordinary directory, unrelated to the one where the sources are, and have the
built objects created there.

--- Now is the first time I heard of that requirement.  Even so, it would not
be hard to implement.

For instance, I frequently (daily) build GNU Emacs 25 and the master branch
(which eventually will become Emacs 26). Git allows me to check both branches
out simultaneously to working directories that point to the same GIT\_DIR, and
then do the builds on directories that may be unrelated among themselves and
to the GIT\_DIR.

> In my current setup, the two working trees are at `/work/emacs/emacs-25` and
> `/work/emacs/master`. The build areas are in a separate place (used to be a
> separate virtual disk when I used VMs): `/scratch/builds/emacs/emacs-25` and
> `/scratch/builds/emacs/master`.
> 
> A similar thing happens with the Linux kernel: I keep a repo of stable-linux
> at `/work/stable-linux`, but I build it under `/scratch` when needed.

One use case for this ability is that you can cross-mount a repo, so the
sources you are testing are remote, but the build is local. A single repo can
feed builds for several operating systems and configurations. Another use case
is to keep the checked-out sources protected by an automated backup--the build
areas don't have to be backed up.

I may be wrong, but the delivered makefiles make fixed directory choices
(currently, in-tree but off-repo). If I am right, this can be fixed easily. Or
maybe the full off-tree functionality is there already. It is bad that I can't
figure it out without going to read the makefiles, but I am not sure what that
means.

--- Should be easy to change.


# Analysis of the deliverables

D1 is at least partly done. It may be fully done, but I can't check for it.

D2 is done, if `make test` does what I think it does. 

The offered code reflects an interest in doing correct builds, and extends
that attitude to doing incremental unit (or sanity) testing. An avowed
characteristic is a concern with shortening the developer's cycle. Having
persistent test results is justified by supporting this goal and not costing
elsewhere. That all the task had been driven by this attitude!

Regrettably, the deliverables undo their good wishes by being extraordinarily
Baroque. The new build system goes over board with changes either gratuituous
(pure cost with no benefit) or harmful (negative utility even if we could
avoid paying their cost).

--- I object to that characterization.  It has no details and hence has no
mechanism to dispute it.  Let me say clearly, everything in the build
system is driven by a functional requirement.  That you do not know what
problem was being solved does not mean that the change is gratuitous or
harmful.

In addition, the goal of imposing one's requirements on external builds is not
a good choice. The externals are black boxes from our perspective. There is no
way to amortize the cost of trying to handle the externals.

--- The externals are a black box.  The ecosystem build simply wraps those
boxes in a way that enables building and deploying them without learning
their meaning.  I am not solving your problem; I am solving the problem
of new engineers.  When I started building the old system; the instructions
did not work.  I am trying to prevent a reoccurence of that with new
folks, and the way to do that is with code.

The following subsections mention the already-known problems with the
over-reaching makefiles. For all of them, one could ask "who in innergy had
this problem, who is now happy it is fixed", and "how much did it cost to fix
this instead of working on the product". And also "why is this still in the
code".


## Host configuration and Build on the same tool
 
One could argue from ideological principles that combining unrelated functions
only makes them brittle. I dislike (see below) invoking principles against
principles, but I don't need to do that: the current system breaks, and cannot
be fixed because it tries to do something it has not enough data for, namely
prequalify the host machine for the build.

A bad consequence is that the build fails in an attempt to check the package
configuration in a ***qualified*** machine (as in, *it was doing builds fine
just now*).

--- Just because the build was working does not mean the machine was
qualified.  In particular, my build was 'working' even though it did not use
qt5.  The ecosystem encodes what it knows of the qualification.

--- We had no mechanism to qualify a machine.  I wrote it into the ecosystem
build because that seemed a reasonable place.  In particular, it helps avoid
a long list of out-of-date instructions.

I have had to work around a complaint about libreadline-dev from
a clean build. I am very irritated that the evidence that this hack does not
work has not been enough to stop the argument.

--- I do not remember you mentioning a problem with libreadline-dev.

Worse off, the alleged check
may "succeed" when it has no effect: if I have installed (say) my own CLANG
somewhere, I don't need GCC. Installing it just wastes my life. The build
system just needs to build and not try to second guess me. Retesting this,
even if to check for the existence of a witness file, is unjustified.

--- Most builds do not need to go through the witness.  Please do not
infer an overhead that is not present.

--- I am not second guessing you.  The check 

> Let me not be shy: I *am* the customer; I don't care what people we
> wouldn't hire anyway may think. Missing this impact and keeping arguing
> is a bad predictor of future Engineering leadership. Never bet on tiring
> your customer!

It may have been OK to separate the prequalification (needed **at** **most**
**once** on a new Ubuntu machine) from the build (run many times a day). This
option was offered, and was rejected on ideological grounds, so I don't feel
like letting the offer stand.

--- Sigh.  I have said it before, and I will say it again.  You do not need to
run the prequalification day-to-day.  The ecosystem build does the check,
and that's a good place for it because the ecosystem is not built every day.

The check for packages must go, this is past non-negotiable.

--- Go from which build?  I think you are infering a problem where none exists.

--- If the check is eliminated entirely, we are back to where I was before,
attempting to build a product with erroneous instructions and exhibiting
bizarre failures due to not having the right packages.  We can can separate
qualification from the build only at the cost of sometimes wasting folks time
when they forget the first step.  And they will forget that step.

It is true that in a BYOC situation we may have competent people who are not
skilled in maintaining an Ubuntu development system. It is also true that
automated build machines need to be configured automatically, or at least
unattended. If this had been brought to attention it would have had to be
considered, and I agree now that a solution is needed. I could have indicated
the best known methods.

--- Innergy has very little need for BYOC.

Instead, Lawrence decided to implement from scratch a non-solution. This
feature of the new build system is a reinvention of the flat tire. Attempting
it is excusable, insisting after the objections were clear borders on
malpractice.

--- Your workflow was not the problem that I am trying to solve.


## Trying to build everything, not just the product

The charming feature of trying to build all the externals before a clean build
can start is completely unnecessary,

--- My makefiles impose no such requirement, so long as what you need is
already available.  Let me make myself clear.  You are presupposing a
problem that does not exist.

and prone to failures that should never be allowed to stop developer builds.
Again, studying the system being superseded would have pointed this out.
Asking would have worked too, except that when I directed that the externals
not be built I was ignored again.

As a consequence, we have no place in the directory tree where we can run a
full product build cleanly, without waiting for the current system to fail on
the externals.  Working around by separately building `verific` and `compass`
(that rename, by the way, is another gratuituous contribution) is a regression
from the previous setup.

--- Sigh.  The separate build of verific and compass is a design feature, not
a workaround.  The current compass makefiles are better than the old ones in
that they do not require attempting to build verific.

--- I said at the time that 'compass' was a placeholder until someone gave
me a name.  No one did.


## Separating the sources into several repos

Dispersing the sources does not help with correctness, off-tree capability, or
regression testing. Assuming there is something to gain, it is not related to
the task at hand.

--- What task?

On first blush it does not seem like a bad idea. For instance, this could be
used to streamline developer builds: clone and build only the product, until
such a time when you need an external built.

--- Yes.

Regrettably, that wasn't the intention. The new makefiles try to build
everything (see above), so there is no good explanation for this change.

--- YES IT WAS THE INTENTION.  IT WORKS TODAY.

Does this separation have a cost?

Of course; experience with the new system has already shown some reasons why
we were better off keeping everything (even the externals) in one directory in
one repository.

  * The first one is that the top of the source tree is not in a repo. Make no
    mistake, there is still a top directory (`/work/innergy`), it is just not
    that useful, What we lost is the ability to say `git clone; cd TOP; make`.
    This can be alleviated by teaching the top makefile how to pull or
    fetch, as has been done. It would not have been needed in a single repo.

  * --- The top of the ecosystem is not the top of our product.
    
  * When you can't use the top makefile because it tries to change your
    machine's configuration, you are limited to the workaround of pulling
    every repo that is part of the product (2 or 3 today). Doing that is
    annoying because you may forget one,

  * --- The makefiles as they exist today make no attempt to change your
    configuration.  They do attempt to validated that your machine has
    what the software need.

  * and becauase you can't just `cd compass; git pull` anymore.

    --- But you can do 'cd compass; make pull'.

  * You have to remember the also unjustified existence of the `repo/`
    subdirectories.

  * --- The repo subdirectories are justified.  The permit the many build
    areas and the repository to exist in one unit.  The organization
    does not require that you manually find a directory somewhere near
    compass, and then point to the repository.
    
This also means that the top makefile must know about cloning repos--yet
another accidentally cohesive function added to the build, but not as
objectionable as the others (because it hasn't failed yet).

--- The purpose of the top makefile is to build the ecosystem.  And it
knows about cloning repos so that a builder does not need to know about
all the various paths to the various master repos.

I don't recall any Engineering organization that employed me where our
sources didn't live in one repository, whose check-out enabled the build
system. There may be a reason.

--- First, all our software is in the repo it was in before.  The only
change is to remove software that is not ours and not under our control.
Second, Sun had many repositories because the cost of scaling to that
many people was not justified by the very low coordination between groups.
Google does have one repository, and they pay an immense amount to
maintain it.

### lnk/ directories

I did not like this feature because I could not understand the cost-benefit
analysis, and said so. Then I remembered that it screws up the debugging
information, and got the impression that we had agreed to remove them (they
are never needed to build, whatever else they may be needed for). Of course,
that was just my imagination.

--- We agreed to remove the lnk directories for the purposes of finding
source files after the build had stabilized, which addresses your concerns.
We did not agree to remove them entirely because they are useful as a
place to cd and view all the relevant sources and none of the non-relevant
sources.

After the fact I have found that this gratuituous feature forces work on the
tagging scripts. Why were tags sacrificed to having redundant symbolic links?
If the tags feature had been kept it would have given us another reason not to
do this.

--- The tagging was not sacrificed for the links.  They are entirely
independent.

--- The tagging was a feature you agreed to defer until the build had
stabilized.  There was never any intent to not implement it.

> Yesterday I found myself editing the `ipa` script and not seeing it propagate
> after making `install-run`. The problem cleared when I hand-removed the script
> from the `run/bin` directory.

--- This is the first time I have heard of such a problem.  In any case, it
would be a bug.

> I have no explanation for this anecdote, but it
> may be that `make` is comparing the time stamp of the link instead of that of
> the file pointed at (not likely).

Make should be looking at the most recent of the relevant timestamps.
It has been working that way for me for a long time.

> Happily enough, there is no need to investigate that possible bug, because...

This must go.

--- We have already agreed to move to a vpath approach for finding sources.


## Changes to the developer UI to the build system

In this area I am happy to acknowledge that I haven't faced the same
unreasonable resistance as in the others. I hesitated between leaving it here
and moving it to the next section; my decision to keep it here is to emphasize
that one doesn't go breaking muscle interfaces casually.

When in doubt, there are ways to avoid imposing what amounts to personal taste
on others.

--- I am happy that you have been so lucky as to always have makefiles do the
same thing.  That has not been my experience.  Being explicit avoids
mistakes.


### Plain `make` should make

Whatever best intentions may recommend otherwise, `make` makes, does not
complain for the lack of a target. It runs the default target, which builds
the product in some usable way. There is nothing unspecific about it.

I am happy to acknowledge that Lawrence agreed to do this, with a suggestion
to run `make check` as the default target. I am OK if there is another target
(say `make build`) that just builds--there are many occasions when we are just
checking syntax, or want to check an intermediate state that should fail some
of its tests, but illuminate something else. 

Of course, we don't push those intermediates to the automated builds, but
being forced to check always only encourages finding a way around. At any
rate, this is as good as it gets, but we should keep an eye on regressions
that try to change what every user of `make` expects.

--- The makefiles are carefully design to run tests only when code that affects
them has changed.  What are you going to do with a build that has changed
code but no testing?  Trust it?

And, anyway, the install targets require a check before they run. (I wonder if
this insistence in checking is not going to come back and hurt us at some
point, but I have no non-hypothetical bad consequences to worrry about.)

--- Yes, they do require a check.  If you have built and tested the code,
that check is essentially free.  If you have not tested, why are you
installing?


#### Other targets must follow suit

For instance, `make pull` should descend to the product repos only. Any action
on the externals requires invoking a target with the externals name. Better
yet, the top make does not have any targets that descenc into the externals
for anything other than running their makes.

--- For developer builds, the top directory is compass, not /work/innergy.
What about this organization causes such a reaction in you?


### The basic targets are spelled runtogether or dash-separated

I am surprised that Lawrence was not aware of the convention. If you tell some
one to type "make clean soul", they will go "$ make cleansoul"; if you say
"make install elsewhere", they will go "$ make install-elsewhere". Changing
the dash to underscore for the sake of asserting one's individuality is not good
Engineering. This should have been acted upon as soon as I reported
it.

--- I chose underscores because mouse actions recognize underscore as part of
a word, which dash does not.  I can live with the loss in functionality, so
I agreed to do make that change when more important problems had been fixed.

Instead, having gotten tired to mistyping, I had to add the trivial fix
that makes both spelling acceptable. (All because the willingness to ignore my
concerns was enough to prevent a one-line change.)

--- And that change was incomplete.  Rather than make the change yourself,
you should have informed me about your pain, rather than complain about a
non-function inconsistency.

The underlying reasoning is that these trivial shows of individuality do the
expected: attract attention to themselves. Now, that is a great way to win a
design review: someone will notice the underscore and not the real problems.

--- The approach was not a show of individuality.  It was a choice based on
function.

I will demand a change on this, but mostly in documentation.

--- I prefer the underscore but won't object to changing to dash.  However,
I object to characterizing a reasoned choice as individuality simply
because you did not understand the reason.



## Lesser questionable features

I will maintain here a list of minor inconveniences or misfeatures I would
have blocked if I had had the option to review the design before work was
spent. These need not go immediately--instead, we should keep an eye on them
and move to better solutions IF the need really arises. Let's say that these
are problems-not-worth-fixing, a very important category in my Engineering
thought.


### inc/ directories

The ostensible goal is to be explicit about what header files are intended as
interfaces used by others. That goal does not imply that the header files must
be separated from their sources! It is a common mistake (e.g., Robert and Guru
started us that way because that's what they did before, and it stayed in place
until it became a problem. I fixed a similar issue at my client's a couple
years ago. VisualStudio sort of encourages this.)

The cost of this separation is minimal if sources and headers are at a fixed
relative location (as in `src/x.cc` and `include/x.hh`, or the
just-had-to-be-different `repo/x.c` and `inc/x.h`),

--- Huh?  repo has nothing to do with the distinction between inc/src.

A developer always knows where to find The Other file: it is either a sibling
of the source file, or a cousin somewhere under an `inc/`.

How much easier it is to find a sibling of the file in the very same
directory... But if segregating the exported headers accomplished *something*,
it may be worth the smallish cost.

--- The separation enables searching, via grep, for all identifiers that
are potentially visible without throwing up the chaff of other identifiers.
However, the split is not trying to solve the problem for the person
finding the header to a source, it is trying to solve the problem of the
person that finds matches from unrelated sources.

Now, it takes only a second to realize that even that minimal consequence can
be avoided: the way to be explicit to a build system is to say it in
`make`. The last version of our older build system had an empty include/
because the leaf makefiles started their action by populating (or updating)
the contents of that directory with their exported headers.

--- That update invalidates timestamps and causes unneeded builds.

In a system that builds the makefiles automatically, it is enough to have a
file (say) `exported-headwrs.mk` in each component source directory, with a
single line

> EXPORTED_HEADERS=PvPaProtocol.hpp

The boilerplate files simply

> -include exported-headers.mk

I can't imagine many good reasons to fix this, but I should say I would have
indicated the cleaner solution instead during design review. Not that anyone
asked.

--- There is a persistent lack of response to my requests for reviews.
In the absence of response, I will make what progress that I can.

# Lessons Learned

Ideas are welcome, as I hope I am not the only one doing the learning.

## The First-Day session is not optional

This was my mistake. No one should be able to opt out of building the system
under another engineer's supervision, and then run the demo (minimally) during
their First Day. Nothing is more important. It doesn't matter how well
documented our practices may become, this is the only contact an engineer
should ever require, and it is not optional.

--- Agreed.

## Write down requirements

Even among respected colleagues, informal specs invite accidents. For now I
intend to use the issues mechanism, without overdoing the detail.

--- And I had a document.  I received almost no comments on that document.

## Establish a culture of no-surprises

Leaving an expert free to run is desirable. When I get a task delegated to me,
I try to make it disappear from my customer's mind. This means that my
customer knows that the problem is as good as solved without breaking anything
else, or that I will get back to them if I shouldn't resolve a tradeoff
on my own. So my bosses let me run free--they don't expect frequent reports,
but they expect I won't surprise them by doing something they would like to
know about before I do it.

--- Also, establish a culture in which problems are anticipated.  I mentioned
some of them in my design document, with a general approach.  I did not
list all of the problems I anticipated.

**No amount of design and code review will succeed if we don't commit to not
surprising one another.** Let's work on this.

--- And no amount of review will succeed if you do not (a) ask me what
problem I was trying to solve before you complain.
(b) presume that I am not 

## There has to be a Decider

Not always the same, but every important decision has an owner. Mutual trust
means that we don't undermine the decider by arguing endlessly--we disagree
and commit, or we resign. No company survives that is arguing all the time.

--- And no company survives if decisions are based on misperceptions.  You
appear to have fundamental misperceptions of the software I have built.


## Argue Consequences, not Principles

Arguing from Principles doesn't work. The other side can always recall or
invent a contrary Principle, and no progress is made. (TV gives frequent
examples these days; I am watching one as I write this.)

--- Principles have consequences, and all of the principles I have
applied here are intended to eliminate bad consequences.

Engineering doesn't advance on Ideology, but on Results. We don't demand
perfection or certainty, but access to information of known quality.  We
suspect any demand of absolute certainty--when you are certain you are no
longer able to test if you are *right*.

--- I am not in a persuit of perfection or certainty.  In fact, I have
a reputation for being ammenable to new information in a changing world.
You are accusing me of a problem that I generally don't have.  In particular,
you seem certain about what the makefiles are doing, but you aren't always
right.  You see problems where none exist.  You see major problems where
I see a small task on the list.

I don't have to recall that every decision is a tradeoff, that all the actions
have an expected utility and cost, including the null action. With those
tools, we don't need no stinking principles to persuade one another.

--- Every decision is a tradeoff, but a tradeoff against what?

In our start-up there is no end of work that needs to be done. Picking
problems for ourselves and for others (especially the junior ones) requires
asking not what Principle supports the decision, but what Consequences we are
facing. Events of low impact or probability can be ignored--we will debug them
if and when they happen. No work should be done on behalf of some abstract
ideal.

--- These makefiles were never persuit of an abstract idea.  They solved
problems that I personally encountered.  But, and think carefully, are you
imposing your notion of an abstract ideal makefile?  Are you persuing
perfection?

So is there room for Principles in Engineering? Surely for ethical principles,
but what else? Principles are implementation hints

--- and they are abbreviations for consequences.

(do not combine apt and make because accidental cohesion is brittle,

--- and represent dependences explicitly because accidental coherence is error.

do not use magic numbers if they can be named,
do not depart from what your users expect unless it buys you something,
do not test for a condition you don't know how to handle...).
--- and test for a condition you know will cause harm if you cannot handle it.

They help us pick between solutions to a problem, but that works only if we
picked good problems, worth solving, worth solving now, worth solving by us
instead of outsourced. If we pick the wrong problem, no amount of ideology
will keep us on track.

--- Agreed.

## Keep all your sources in a single repository

I am surprised how quickly this one went bad--I would have sworn that it
didn't matter, and might even be useful. I had thought of getting the
Externals out myself.

Now I know good reasons for not separating what belongs together, any more
than putting together what should be apart.

--- All our sources are in one repository.

## Occam's razor

This is a lesson I already learned--I just couldn't apply it because I never
reviewed the plan. I would have queried Lawrence about why repo/ and inc/ and
all the other novelties were needed. The right thing was to implement what was
needed (none of the above) and see what else may be needed later. Multiplying
unwarranted names and entities is hard to undo, but easy to avoid.

--- I implemented what I thought was needed bases on my experience in other
projects.  Admittedly, I was anticipating problems that were apparently not
on your list.

Also, anything that falls to the Razor was not a solid thing to work on. So,
no biggie--it is not like the World missed the last change to misspell
"lnk". There are better things to do, and clearing these trivia will enable us
to tackle them.

--- It is not the razor that is at issue, but the set of problems.


## Imitate the cats

It is not what one says, but how one says it. (Cats are famous for making do
with two sounds, richly modulated.)

When offering a solution for a problem (assuning it is a Good Problem), it is
better to present the benefits of what the new work will *enable*, not what it
will *prevent*. Lawrence should practice looking for the feature allowed, not
for the bug avoided (especially if the bug is trivial to fix or imaginary).

--- I outlined the primary benefits.  I the absence of feedback, there was
no point in detailing secondary benefits.

My own reaction to proposals that aim at certainty in safety is to discount
them to zero present value--then any cost kills them. We have too many good
things to achieve that we should not spend any time punishing the guilty or
worrying about asteroid collisions. Or imagining that absolute safety is
possible at a sane cost. Life is an assumed-risk activity.

--- I really do not understand why you think I am striving for certainty.
My tolerance for uncertainty is higher than that of many others.  However,
if I have low-cost technical means to prevent problems that I have encountered
elsewhere, why should I not employ them?


# The way forward

The goal still remains to hand over the Engineering leadership to Lawrence;
the miscommunication in this episode is just that. Therefore, Lawrence must
get visibly important development goals, and people to lead; the only proviso
is that a commitment is needed from his part to work as an Engineering leader:
by cultivating among the team a culture of identifying the customer and
refraining from arguing with that customer, of picking problems to solve
exclusively in terms of the consequences for innergy of solving (or not
solving) them, and of not surprising one's colleagues.

--- This deserves more discussion, but not now.

Soon Lawrence will have to be able to say to others "I heard you, we have
discussed it, but it is my call". No better way to get him ready than for him
that to practice the Disagree But Commit strategy in this project.

--- I don't think you have heard me.

In any case, we need to be done with the build system project quickly. This
may leave some work for later or never, so let's do what is absolutely
necessary first, and move on to other things. I for one never expected to
invest so much time arguing about a trivial upgrade.


## Absolute requirements

I must not lose any build functionality.

--- Losing build functionality was never an intent.  Incremental development
was the intent.

Once the below actions are complete I will provide the implementation of
tagging and that will be the cherry on top. We will have most of the previous
functionality plus the two new features, plus the bonuses (test persistence,
others?).

***The meeting in person must not leave any doubts that this is the plan of
record, and that it will be implemented with great haste.***

### Discard all the code that tries to test or enforce a package list

There is a way explained below to take care of the once-only needs of BYOC
contributors.

### No link directories

The build objects are to depend on the source files under source control, and
possibly on relocated or generated files, never on links, even hard.

--- Discussed above.

### Make at the top just builds the product

The top is `/work/innergy` or its alternative locations. The product 
today is `verific/` and `compass/`. It is OK to leave `algochips/` out
for now; we can revise this later.

--- I still think you are not groking what I have done.

It is OK to keep `check` as the default target, but the `build` target must
exist, and not do anything but run the build.

--- The build target already exists.  It is everywhere.


### Making the externals is optional and explicit

For instance, to get `systemc/` built, one does `cd systemc; make
install-local`.

--- Setting aside that we have three places to install, the build does that.

No target builds any externals implicitly. That is how it worked before,
so this just restores sanity.

--- Sigh, and that is how it works now.


### Document the dash-separated targets

The synonyms may stay if this is an issue of muscle-memory. They may not be
documented or (much less) recommended. We will stop attracting attention to
our tastes.

--- I won't object to changing to dashes everywere.  I do object to having
them in some places and not in others; which you fix does.


### Document the apt-clone strategy

After a new user has cloned `ecosystem/`, he or she should be able to initiate
a restore.  We can declare victory by indicating where the clones are and how
to restore them. I have code that identifies which clone is needed (from the
release identification data, not from sniffing packages), but just explaining
what to do is enough.

--- I have no objection to apt-clone, but it surprises me because it imposes
a much tighter control over the user than my makefiles, which is inconsistent
with you stated preference for letting the user do what he wants.  That is,
if enforcing a small set of packages is a problem, why is install a whole
raft of packages not a problem.  In particular, I would be very upset if 
apt-clone pushed unity on me.

The build system should not offer any automation of this. None. Ever.

--- Which build system?

I will mail Lawrence a copy of the currently known-good clone for 15.10 as
soon as we get his commitmment.

--- I have no objection to a clone as means to get started.


## Under review

These actions are not needed to declare victory and move on now. They can be
treated as a fill-in priority (which means we may never get around to doing
them).


### Off-Tree build completion

Confirm that the build areas can be disconnected from the source areas
already, or else provide a high-level plan for how we could do this later. No
need to actually implement it, but let's make sure we understand how much
notice in advance of the need we will require. The alternative is to port the
build to a mechanism that is known to do this, like the autotools. That bounds
the acceptable effort.

--- I see no inherent problem in doing this.  The build already supports
multiple off-tree build areas, though only as directory peers of the repo.


### Replace the inc/ dirs with a make feature

As explained above, `inc/` was never needed (and should have been called
`include/` if it was needed). Removing this is one fewer distraction.

--- The reason for 'inc' instead of 'include' was to reduce the bulk of
the log file and make reading it easier.

--- The inc directory serves a purpose, as I explained above.

However, removing a distraction is not valuable enough to schedule it
now. Maybe we will have to live forever with this inelegant mar in our
polish--living with it may be a good way to remind us that we don't need
perfection.


### Flatten the components

When there is no `inc/`, `repo/` should go. Make each component host its
own .git (or whatever we are using at the time). This will return the ability
to `cd compass; git pull; make` without distracting extra entities. As this
depends on something we may never do, it is in limbo too. Amazingly, it would
just restore what was working when this task started.

--- I do not understand why you object to "cd compass; make pull" or
"cd compass/repo; make pull".


# Conclusion

This task has taken an inordinate amount of effort from all the involved,
which included Cameron and Sameer at some points. I assume responsibility for
not stopping the waste before, and I have provided here a workable plan to get
done with this task at limited losses. If we get together behind this plan we
may be able to make the episode a plus instead of the runaway minus it has
become.

--- I want you to understand what is present, and I don't think you do.


<-- end -->
