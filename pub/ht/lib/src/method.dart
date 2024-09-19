enum Method {
  /// The ACL method modifies the access control list (which can be read via the DAV:acl
  /// property) of a resource.
  ///
  /// See [RFC3744, Section 8.1][].
  ///
  /// [RFC3744, Section 8.1]: https://tools.ietf.org/html/rfc3744#section-8.1
  acl,

  /// A collection can be placed under baseline control with a BASELINE-CONTROL request.
  ///
  /// See [RFC3253, Section 12.6][].
  ///
  /// [RFC3253, Section 12.6]: https://tools.ietf.org/html/rfc3253#section-12.6
  baselineControl('BASELINE-CONTROL'),

  /// The BIND method modifies the collection identified by the Request- URI, by adding a new
  /// binding from the segment specified in the BIND body to the resource identified in the BIND
  /// body.
  ///
  /// See [RFC5842, Section 4][].
  ///
  /// [RFC5842, Section 4]: https://tools.ietf.org/html/rfc5842#section-4
  bind,

  /// A CHECKIN request can be applied to a checked-out version-controlled resource to produce a
  /// new version whose content and dead properties are copied from the checked-out resource.
  ///
  /// See [RFC3253, Section 4.4][] and [RFC3253, Section 9.4][].
  ///
  /// [RFC3253, Section 4.4]: https://tools.ietf.org/html/rfc3253#section-4.4
  /// [RFC3253, Section 9.4]: https://tools.ietf.org/html/rfc3253#section-9.4
  checkin,

  /// A CHECKOUT request can be applied to a checked-in version-controlled resource to allow
  /// modifications to the content and dead properties of that version-controlled resource.
  ///
  /// See [RFC3253, Section 4.3][] and [RFC3253, Section 8.8][].
  ///
  /// [RFC3253, Section 4.3]: https://tools.ietf.org/html/rfc3253#section-4.3
  /// [RFC3253, Section 8.8]: https://tools.ietf.org/html/rfc3253#section-8.8
  checkout,

  /// The CONNECT method requests that the recipient establish a tunnel to the destination origin
  /// server identified by the request-target and, if successful, thereafter restrict its
  /// behavior to blind forwarding of packets, in both directions, until the tunnel is closed.
  ///
  /// See [RFC7231, Section 4.3.6][].
  ///
  /// [RFC7231, Section 4.3.6]: https://tools.ietf.org/html/rfc7231#section-4.3.6
  connect,

  /// The COPY method creates a duplicate of the source resource identified by the Request-URI,
  /// in the destination resource identified by the URI in the Destination header.
  ///
  /// See [RFC4918, Section 9.8][].
  ///
  /// [RFC4918, Section 9.8]: https://tools.ietf.org/html/rfc4918#section-9.8
  copy,

  /// The DELETE method requests that the origin server remove the association between the target
  /// resource and its current functionality.
  ///
  /// See [RFC7231, Section 4.3.5][].
  ///
  /// [RFC7231, Section 4.3.5]: https://tools.ietf.org/html/rfc7231#section-4.3.5
  delete,

  /// The GET method requests transfer of a current selected representation for the target
  /// resource.
  ///
  /// See [RFC7231, Section 4.3.1][].
  ///
  /// [RFC7231, Section 4.3.1]: https://tools.ietf.org/html/rfc7231#section-4.3.1
  get,

  /// The HEAD method is identical to GET except that the server MUST NOT send a message body in
  /// the response.
  ///
  /// See [RFC7231, Section 4.3.2][].
  ///
  /// [RFC7231, Section 4.3.2]: https://tools.ietf.org/html/rfc7231#section-4.3.2
  head,

  /// A LABEL request can be applied to a version to modify the labels that select that version.
  ///
  /// See [RFC3253, Section 8.2][].
  ///
  /// [RFC3253, Section 8.2]: https://tools.ietf.org/html/rfc3253#section-8.2
  label,

  /// The LINK method establishes one or more Link relationships between the existing resource
  /// identified by the Request-URI and other existing resources.
  ///
  /// See [RFC2068, Section 19.6.1.2][].
  ///
  /// [RFC2068, Section 19.6.1.2]: https://tools.ietf.org/html/rfc2068#section-19.6.1.2
  link,

  /// The LOCK method is used to take out a lock of any access type and to refresh an existing
  /// lock.
  ///
  /// See [RFC4918, Section 9.10][].
  ///
  /// [RFC4918, Section 9.10]: https://tools.ietf.org/html/rfc4918#section-9.10
  lock,

  /// The MERGE method performs the logical merge of a specified version (the "merge source")
  /// into a specified version-controlled resource (the "merge target").
  ///
  /// See [RFC3253, Section 11.2][].
  ///
  /// [RFC3253, Section 11.2]: https://tools.ietf.org/html/rfc3253#section-11.2
  merge,

  /// A MKACTIVITY request creates a new activity resource.
  ///
  /// See [RFC3253, Section 13.5].
  ///
  /// [RFC3253, Section 13.5]: https://tools.ietf.org/html/rfc3253#section-13.5
  mkActivity,

  /// An HTTP request using the MKCALENDAR method creates a new calendar collection resource.
  ///
  /// See [RFC4791, Section 5.3.1][] and [RFC8144, Section 2.3][].
  ///
  /// [RFC4791, Section 5.3.1]: https://tools.ietf.org/html/rfc4791#section-5.3.1
  /// [RFC8144, Section 2.3]: https://tools.ietf.org/html/rfc8144#section-2.3
  mkCalendar,

  /// MKCOL creates a new collection resource at the location specified by the Request-URI.
  ///
  /// See [RFC4918, Section 9.3][], [RFC5689, Section 3][] and [RFC8144, Section 2.3][].
  ///
  /// [RFC4918, Section 9.3]: https://tools.ietf.org/html/rfc4918#section-9.3
  /// [RFC5689, Section 3]: https://tools.ietf.org/html/rfc5689#section-3
  /// [RFC8144, Section 2.3]: https://tools.ietf.org/html/rfc5689#section-3
  mkCol,

  /// The MKREDIRECTREF method requests the creation of a redirect reference resource.
  ///
  /// See [RFC4437, Section 6][].
  ///
  /// [RFC4437, Section 6]: https://tools.ietf.org/html/rfc4437#section-6
  mkRedirectRef,

  /// A MKWORKSPACE request creates a new workspace resource.
  ///
  /// See [RFC3253, Section 6.3][].
  ///
  /// [RFC3253, Section 6.3]: https://tools.ietf.org/html/rfc3253#section-6.3
  mkWorkspace,

  /// The MOVE operation on a non-collection resource is the logical equivalent of a copy (COPY),
  /// followed by consistency maintenance processing, followed by a delete of the source, where
  /// all three actions are performed in a single operation.
  ///
  /// See [RFC4918, Section 9.9][].
  ///
  /// [RFC4918, Section 9.9]: https://tools.ietf.org/html/rfc4918#section-9.9
  move,

  /// The OPTIONS method requests information about the communication options available for the
  /// target resource, at either the origin server or an intervening intermediary.
  ///
  /// See [RFC7231, Section 4.3.7][].
  ///
  /// [RFC7231, Section 4.3.7]: https://tools.ietf.org/html/rfc7231#section-4.3.7
  options,

  /// The ORDERPATCH method is used to change the ordering semantics of a collection, to change
  /// the order of the collection's members in the ordering, or both.
  ///
  /// See [RFC3648, Section 7][].
  ///
  /// [RFC3648, Section 7]: https://tools.ietf.org/html/rfc3648#section-7
  orderPatch,

  /// The PATCH method requests that a set of changes described in the request entity be applied
  /// to the resource identified by the Request- URI.
  ///
  /// See [RFC5789, Section 2][].
  ///
  /// [RFC5789, Section 2]: https://tools.ietf.org/html/rfc5789#section-2
  patch,

  /// The POST method requests that the target resource process the representation enclosed in
  /// the request according to the resource's own specific semantics.
  ///
  /// For example, POST is used for the following functions (among others):
  ///
  ///   - Providing a block of data, such as the fields entered into an HTML form, to a
  ///     data-handling process;
  ///   - Posting a message to a bulletin board, newsgroup, mailing list, blog, or similar group
  ///     of articles;
  ///   - Creating a new resource that has yet to be identified by the origin server; and
  ///   - Appending data to a resource's existing representation(s).
  ///
  /// See [RFC7231, Section 4.3.3][].
  ///
  /// [RFC7231, Section 4.3.3]: https://tools.ietf.org/html/rfc7231#section-4.3.3
  post,

  /// This method is never used by an actual client. This method will appear to be used when an
  /// HTTP/1.1 server or intermediary attempts to parse an HTTP/2 connection preface.
  ///
  /// See [RFC7540, Section 3.5][] and [RFC7540, Section 11.6][]
  ///
  /// [RFC7540, Section 3.5]: https://tools.ietf.org/html/rfc7540#section-3.5
  /// [RFC7540, Section 11.6]: https://tools.ietf.org/html/rfc7540#section-11.6
  pri,

  /// The PROPFIND method retrieves properties defined on the resource identified by the
  /// Request-URI.
  ///
  /// See [RFC4918, Section 9.1][] and [RFC8144, Section 2.1][].
  ///
  /// [RFC4918, Section 9.1]: https://tools.ietf.org/html/rfc4918#section-9.1
  /// [RFC8144, Section 2.1]: https://tools.ietf.org/html/rfc8144#section-2.1
  propFind,

  /// The PROPPATCH method processes instructions specified in the request body to set and/or
  /// remove properties defined on the resource identified by the Request-URI.
  ///
  /// See [RFC4918, Section 9.2][] and [RFC8144, Section 2.2][].
  ///
  /// [RFC4918, Section 9.2]: https://tools.ietf.org/html/rfc4918#section-9.2
  /// [RFC8144, Section 2.2]: https://tools.ietf.org/html/rfc8144#section-2.2
  propPatch,

  /// The PUT method requests that the state of the target resource be created or replaced with
  /// the state defined by the representation enclosed in the request message payload.
  ///
  /// See [RFC7231, Section 4.3.4][].
  ///
  /// [RFC7231, Section 4.3.4]: https://tools.ietf.org/html/rfc7231#section-4.3.4
  put,

  /// The REBIND method removes a binding to a resource from a collection, and adds a binding to
  /// that resource into the collection identified by the Request-URI.
  ///
  /// See [RFC5842, Section 6][].
  ///
  /// [RFC5842, Section 6]: https://tools.ietf.org/html/rfc5842#section-6
  rebind,

  /// A REPORT request is an extensible mechanism for obtaining information about a resource.
  ///
  /// See [RFC3253, Section 3.6][] and [RFC8144, Section 2.1][].
  ///
  /// [RFC3253, Section 3.6]: https://tools.ietf.org/html/rfc3253#section-3.6
  /// [RFC8144, Section 2.1]: https://tools.ietf.org/html/rfc8144#section-2.1
  report,

  /// The client invokes the SEARCH method to initiate a server-side search. The body of the
  /// request defines the query.
  ///
  /// See [RFC5323, Section 2][].
  ///
  /// [RFC5323, Section 2]: https://tools.ietf.org/html/rfc5323#section-2
  search,

  /// The TRACE method requests a remote, application-level loop-back of the request message.
  ///
  /// See [RFC7231, Section 4.3.8][].
  ///
  /// [RFC7231, Section 4.3.8]: https://tools.ietf.org/html/rfc7231#section-4.3.8
  trace,

  /// The UNBIND method modifies the collection identified by the Request- URI by removing the
  /// binding identified by the segment specified in the UNBIND body.
  ///
  /// See [RFC5842, Section 5][].
  ///
  /// [RFC5842, Section 5]: https://tools.ietf.org/html/rfc5842#section-5
  unbind,

  /// An UNCHECKOUT request can be applied to a checked-out version-controlled resource to cancel
  /// the CHECKOUT and restore the pre-CHECKOUT state of the version-controlled resource.
  ///
  /// See [RFC3253, Section 4.5][].
  ///
  /// [RFC3253, Section 4.5]: https://tools.ietf.org/html/rfc3253#section-4.5
  uncheckout,

  /// The UNLINK method removes one or more Link relationships from the existing resource
  /// identified by the Request-URI.
  ///
  /// See [RFC2068, Section 19.6.1.3][].
  ///
  /// [RFC2068, Section 19.6.1.3]: https://tools.ietf.org/html/rfc2068#section-19.6.1.3
  unlink,

  /// The UNLOCK method removes the lock identified by the lock token in the Lock-Token request
  /// header.
  ///
  /// See [RFC4918, Section 9.11][].
  ///
  /// [RFC4918, Section 9.11]: https://tools.ietf.org/html/rfc4918#section-9.11
  unlock,

  /// The UPDATE method modifies the content and dead properties of a checked-in
  /// version-controlled resource (the "update target") to be those of a specified version (the
  /// "update source") from the version history of that version-controlled resource.
  ///
  /// See [RFC3253, Section 7.1][].
  ///
  /// [RFC3253, Section 7.1]: https://tools.ietf.org/html/rfc3253#section-7.1
  update,

  /// The UPDATEREDIRECTREF method requests the update of a redirect reference resource.
  ///
  /// See [RFC4437, Section 7][].
  ///
  /// [RFC4437, Section 7]: https://tools.ietf.org/html/rfc4437#section-7
  updateRedirectRef,

  /// A VERSION-CONTROL request can be used to create a version-controlled resource at the
  /// request-URL.
  ///
  /// See [RFC3253, Section 3.5].
  ///
  /// [RFC3253, Section 3.5]: https://tools.ietf.org/html/rfc3253#section-3.5
  versionControl('VERSION-CONTROL'),

  //-------------
  ;

  /// The method emun name patch.
  final String? $patch;
  const Method([this.$patch]);

  factory Method.fromString(String method) {
    for (final value in Method.values) {
      if (value.toString() == method.toUpperCase()) {
        return value;
      }
    }

    throw UnsupportedError('This is $method not supported.');
  }

  @override
  toString() => ($patch ?? name).toUpperCase();

  /// Whether a method is considered "safe", meaning the request is essentially read-only.
  ///
  /// See [the spec](https://tools.ietf.org/html/rfc7231#section-4.2.1) for more details.
  bool isSafe() {
    return switch (this) {
      get ||
      head ||
      options ||
      pri ||
      propFind ||
      report ||
      search ||
      trace =>
        true,
      _ => false,
    };
  }
}
