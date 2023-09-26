<h1 align="center">Codifying security knowledge</h1>
<h3 align="center">Going from security advisory to CodeQL query</h3>
<h5 align="center">@thezefan, @lcartey, @rvermeulen</h3>

<p align="center">
  <a href="#mega-prerequisites">Prerequisites</a> •  
  <a href="#books-resources">Resources</a> •
  <a href="#learning-objectives">Learning Objectives</a>
</p>

> Please provide a description of your workshop.

- **Who is this for**: Security Engineers, Security Researchers, Developers.
- **What you'll learn**: Learn how to use CodeQL for code exploration and for finding security issues.
- **What you'll build**: Build a CodeQL query based on a security advisory to find a SQL injection.

## Learning Objectives

In this workshop, you will:

  - Learn how to use CodeQL to explore a code base.
  - Learn how to use CodeQL to codify security knowledge and find a SQL injection issue.
  - Learn how to reuse codified security knowledge to find variants or new security issues.

## :mega: Prerequisites

Before joining the workshop, there are a few items that you will need to install or bring with you.

- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension](https://marketplace.visualstudio.com/items?itemName=github.vscode-codeql).
- Install the required CodeQL pack dependencies by running the command `CodeQL: Install pack dependencies` to install the dependencies for the pack `githubuniverseworkshop/sql-injection-queries`.
- Set the current database to `xwiki-platform-db.zip`

## :books: Resources

- [CodeQL documentation](https://codeql.github.com/docs/)
- [SQL injection](https://portswigger.net/web-security/sql-injection)
- [QL language reference](https://codeql.github.com/docs/ql-language-reference/)
- [CodeQL library for Java](https://codeql.github.com/codeql-standard-libraries/java/)

## Workshop

Welcome to the workshop Codifying security knowledge - Going from security advisory to CodeQL query!
In this workshop we will apply CodeQL to gain a better understanding of a security issues reported in a security advisory, codify this new security knowledge so we can
find the security issue, and learn how this codified knowledge can help find variants and other security issues.

Before we get started it is important that all of the prerequisites are met so you participate in the workshop.

The workshop is divided into multiple sections and each section has a corresponding checkpoint (see `java/sql-injection/src/checkpoints`) that you can use to resume from if you were unable to complete the previous section.

### The known security vulnerability

In this workshop we will look for a known _SQL injection vulnerabilities_ in the [XWiki Platform](https://xwiki.org)'s ratings API component. Such vulnerabilities can occur in applications when information that is controlled by a user makes its way to application code that insecurely construct a SQL query and executes it. SQL queries insecurely constructed from user input can be rewritten to perform unintended actions such as the disclosure of sensitive information.

The SQL injection discussed in this workshop is reviewed in [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories).

To find the SQL injection we are going to:

- Identify the vulnerable method discussed in the advisory and determine how it is used.
- Model the vulnerable method as a SQL sink so the SQL injection query is aware of this method.
- Identify how the vulnerable method can be used by finding new XWiki specific entrypoints.
- Model the new entrypoints as a source of untrusted data that can be used by CodeQL queries.
  
Once we have completed the above steps, we can see whether the models, our codified security knowledge, can uncover variants or possible
other security issues.

### Finding the insecure function

In the security advisory [GHSA-79rg-7mv3-jrr5](https://github.com/advisories/GHSA-79rg-7mv3-jrr5) in [GitHub Advisory Database](https://github.com/advisories) we learn of a [Jira issue](https://jira.xwiki.org/browse/XWIKI-17662) that discusses SQL injection in more detail.

There exists a method `getAverageRating` whose two parameters are directly used to produce a SQL request.
We will use CodeQL to find the method and use the results to better understand how the SQL injection can manifest.

1. Find all the methods with the name `getAverageRating`
   - The `java` module provides a class `Method` to reason about methods in a program.
   - The class `Method` provides the member predicates `getName` and `hasName` to reason about the name of a method.
1. Refine the set of results by limiting it to methods named `getAverageRating` where the first parameter is named `fromsql`.
   - The class `Method` provides the member predicate `getParameter` that expects an index to retrieve the corresponding parameter, if any.
   - The class `Parameter` provides the member predicates `getName` and `hasName` to reason about the name of a parameter.

From the results of the query we find that the method `getAverageRating` passes the `fromsql` parameter to a method named `getAverageRatingFromQuery`.

1. Find all the methods with the name `getAverageRatingFromQuery`.
1. Reduce the number of results by filtering uninteresting results.
   - For example, only consider methods that have a body.

One of the methods uses the `fromsql` parameter to construct a SQL query.
Let's further explore this method to determine how the SQL injection manifests.

### Identifying and modelling a SQL sink

You can copy [CheckPoint1.ql](java/sql-injection/src/checkpoints/CheckPoint1.ql) to continue this section if you where unable to finish the previous section.

Now that we have found the location of where the SQL statement is constructed we can determine where it is used.

Following the use of `sql`, we can see it is passed to a method `search`.

1. Find all the calls to a method named `search`.
   - Calls to methods are method accesses. The class `MethodAccess` allows you to reason about method accesses.
   - The class `MethodAccess` provides a member predicate `getMethod` allows you to reason about the method being accessed.
   - The class `MethodAccess` provides the member predicates `getName` and `hasName` to reason about the name of a method.

The method name `search` is very common so the above query provides a lot of results. Too many for manual investigation.
Lets refine the set of results to a more manageable set.

1. Find all the method access in the method `getAverageRatingFromQuery`.
   - The class `MethodAccess` provides the member predicate [getEnclosingCallable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Expr.qll/predicate.Expr$MethodAccess$getEnclosingCallable.0.html) to reason about the method or constructor containing the method access.
   - The class [Callable](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Callable.html) provides the member predicates [getName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$getName.0.html) and [hasName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Element.qll/predicate.Element$Element$hasName.1.html) to reason about the name of a method.

Now that we have found the sink we want to uniquely identified it.
In Java we can use an elements fully qualified name so let use CodeQL to find it for the method `search`.

1. Select the qualified name of the method `search`.
   - The class [Method](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/type.Member$Method.html) provides the member predicate [getQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$getQualifiedName.0.html) useful fore debugging. The more efficient [hasQualifiedName](https://codeql.github.com/codeql-standard-libraries/java/semmle/code/java/Member.qll/predicate.Member$Member$hasQualifiedName.3.html) for restricting a method.

