/// HTTP response status codes.
///
/// As defined by [rfc7231 section 6](https://tools.ietf.org/html/rfc7231#section-6).
/// [Read more](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
enum StatusCode {
  /// 100 Continue
  ///
  /// This interim response indicates that everything so far is OK and that
  /// the client should continue the request, or ignore the response if
  /// the request is already finished.
  continue_(100, 'Continue'),

  /// 101 Switching Protocols
  ///
  /// This code is sent in response to an Upgrade request header from the
  /// client, and indicates the protocol the server is switching to.
  switchingProtocols(101, 'Switching Protocols'),

  /// 103 Early Hints
  ///
  /// This status code is primarily intended to be used with the Link header,
  /// letting the user agent start preloading resources while the server
  /// prepares a response.
  earlyHints(103, 'Early Hints'),

  /// 200 Ok
  ///
  /// The request has succeeded
  ok(200, 'Ok'),

  /// 201 Created
  ///
  /// The request has succeeded and a new resource has been created as a
  /// result. This is typically the response sent after POST requests, or
  /// some PUT requests.
  created(201, 'Created'),

  /// 202 Accepted
  ///
  /// The request has been received but not yet acted upon. It is
  /// noncommittal, since there is no way in HTTP to later send an
  /// asynchronous response indicating the outcome of the request. It is
  /// intended for cases where another process or server handles the request,
  /// or for batch processing.
  accepted(202, 'Accepted'),

  /// 203 Non Authoritative Information
  ///
  /// This response code means the returned meta-information is not exactly
  /// the same as is available from the origin server, but is collected
  /// from a local or a third-party copy. This is mostly used for mirrors
  /// or backups of another resource. Except for that specific case, the
  /// "200 OK" response is preferred to this status.
  nonAuthoritativeInformation(203, 'Non Authoritative Information'),

  /// 204 No Content
  ///
  /// There is no content to send for this request, but the headers may be
  /// useful. The user-agent may update its cached headers for this
  /// resource with the new ones.
  noContent(204, 'No Content'),

  /// 205 Reset Content
  ///
  /// Tells the user-agent to reset the document which sent this request.
  resetContent(205, 'No Content'),

  /// 206 Partial Content
  ///
  /// This response code is used when the Range header is sent from the client
  /// to request only part of a resource.
  partialContent(206, 'Partial Content'),

  /// 207 Multi-Status
  ///
  /// A Multi-Status response conveys information about
  /// multiple resources in situations where multiple
  /// status codes might be appropriate.
  multiStatus(207, 'Multi-Status'),

  /// 226 Im Used
  ///
  /// The server has fulfilled a GET request for the resource, and the
  /// response is a representation of the result of one or more
  /// instance-manipulations applied to the current instance.
  imUsed(226, 'Im Used'),

  /// 300 Multiple Choice
  ///
  /// The request has more than one possible response. The user-agent or user
  /// should choose one of them. (There is no standardized way of choosing
  /// one of the responses, but HTML links to the possibilities are
  /// recommended so the user can pick.)
  multipleChoice(300, 'Multiple Choice'),

  /// 301 Moved Permanently
  ///
  /// The URL of the requested resource has been changed permanently. The new
  /// URL is given in the response.
  movedPermanently(301, 'Moved Permanently'),

  /// 302 Found
  ///
  /// This response code means that the URI of requested resource has been
  /// changed temporarily. Further changes in the URI might be made in the
  /// future. Therefore, this same URI should be used by the client in
  /// future requests.
  found(302, 'Found'),

  /// 303 See Other
  ///
  /// The server sent this response to direct the client to get the requested
  /// resource at another URI with a GET request.
  seeOther(303, 'See Other'),

  /// 304 Not Modified
  ///
  /// This is used for caching purposes. It tells the client that the response
  /// has not been modified, so the client can continue to use the same
  /// cached version of the response.
  notModified(304, 'Not Modified'),

  /// 307 Temporary Redirect
  ///
  /// The server sends this response to direct the client to get the requested
  /// resource at another URI with same method that was used in the prior
  /// request. This has the same semantics as the 302 Found HTTP response
  /// code, with the exception that the user agent must not change the
  /// HTTP method used: If a POST was used in the first request, a POST must
  /// be used in the second request.
  temporaryRedirect(307, 'Temporary Redirect'),

  /// 308 Permanent Redirect
  ///
  /// This means that the resource is now permanently located at another URI,
  /// specified by the Location: HTTP Response header. This has the same
  /// semantics as the 301 Moved Permanently HTTP response code, with the
  /// exception that the user agent must not change the HTTP method
  /// used: If a POST was used in the first request, a POST must be used in
  /// the second request.
  permanentRedirect(308, 'Permanent Redirect'),

  /// 400 Bad Request
  ///
  /// The server could not understand the request due to invalid syntax.
  badRequest(400, 'Bad Request'),

  /// 401 Unauthorized
  ///
  /// Although the HTTP standard specifies "unauthorized", semantically this
  /// response means "unauthenticated". That is, the client must
  /// authenticate itself to get the requested response.
  unauthorized(401, 'Unauthorized'),

  /// 402 Payment Required
  ///
  /// This response code is reserved for future use. The initial aim for
  /// creating this code was using it for digital payment systems, however
  /// this status code is used very rarely and no standard convention
  /// exists.
  paymentRequired(402, 'Payment Required'),

  /// 403 Forbidden
  ///
  /// The client does not have access rights to the content; that is, it is
  /// unauthorized, so the server is refusing to give the requested
  /// resource. Unlike 401, the client's identity is known to the server.
  forbidden(403, 'Forbidden'),

  /// 404 Not Found
  ///
  /// The server can not find requested resource. In the browser, this means
  /// the URL is not recognized. In an API, this can also mean that the
  /// endpoint is valid but the resource itself does not exist. Servers
  /// may also send this response instead of 403 to hide the existence of
  /// a resource from an unauthorized client. This response code is probably
  /// the most famous one due to its frequent occurrence on the web.
  notFound(404, 'Not Found'),

  /// 405 Method Not Allowed
  ///
  /// The request method is known by the server but has been disabled and
  /// cannot be used. For example, an API may forbid DELETE-ing a
  /// resource. The two mandatory methods, GET and HEAD, must never be
  /// disabled and should not return this error code.
  methodNotAllowed(405, 'Method Not Allowed'),

  /// 406 Not Acceptable
  ///
  /// This response is sent when the web server, after performing
  /// server-driven content negotiation, doesn't find any content that
  /// conforms to the criteria given by the user agent.
  notAcceptable(406, 'Not Acceptable'),

  /// 407 Proxy Authentication Required
  ///
  /// This is similar to 401 but authentication is needed to be done by a
  /// proxy.
  proxyAuthenticationRequired(407, 'Proxy Authentication Required'),

  /// 408 Request Timeout
  ///
  /// This response is sent on an idle connection by some servers, even
  /// without any previous request by the client. It means that the server
  /// would like to shut down this unused connection. This response is
  /// used much more since some browsers, like Chrome, Firefox 27+,
  /// or IE9, use HTTP pre-connection mechanisms to speed up surfing. Also
  /// note that some servers merely shut down the connection without
  /// sending this message.
  requestTimeout(408, 'Request Timeout'),

  /// 409 Conflict
  ///
  /// This response is sent when a request conflicts with the current state of
  /// the server.
  conflict(409, 'Conflict'),

  /// 410 Gone
  ///
  /// This response is sent when the requested content has been permanently
  /// deleted from server, with no forwarding address. Clients are
  /// expected to remove their caches and links to the resource. The HTTP
  /// specification intends this status code to be used for "limited-time,
  /// promotional services". APIs should not feel compelled to indicate
  /// resources that have been deleted with this status code.
  gone(410, 'Gone'),

  /// 411 Length Required
  ///
  /// Server rejected the request because the Content-Length header field is
  /// not defined and the server requires it.
  lengthRequired(411, 'Length Required'),

  /// 412 Precondition Failed
  ///
  /// The client has indicated preconditions in its headers which the server
  /// does not meet.
  preconditionFailed(412, 'Precondition Failed'),

  /// 413 Payload Too Large
  ///
  /// Request entity is larger than limits defined by server; the server might
  /// close the connection or return an Retry-After header field.
  payloadTooLarge(413, 'Payload Too Large'),

  /// 414 URI Too Long
  ///
  /// The URI requested by the client is longer than the server is willing to
  /// interpret.
  uriTooLong(414, 'URI Too Long'),

  /// 415 Unsupported Media Type
  ///
  /// The media format of the requested data is not supported by the server,
  /// so the server is rejecting the request.
  unsupportedMediaType(415, 'Unsupported Media Type'),

  /// 416 Requested Range Not Satisfiable
  ///
  /// The range specified by the Range header field in the request can't be
  /// fulfilled; it's possible that the range is outside the size of the
  /// target URI's data.
  requestedRangeNotSatisfiable(416, 'Requested Range Not Satisfiable'),

  /// 417 Expectation Failed
  ///
  /// This response code means the expectation indicated by the Expect request
  /// header field can't be met by the server.
  expectationFailed(417, 'Expectation Failed'),

  ///
  /// 418 I'm a teapot
  ///
  /// The server refuses the attempt to brew coffee with a teapot.
  imATeapot(418, 'I\'m a teapot'),

  /// 421 Misdirected Request
  ///
  /// The request was directed at a server that is not able to produce a
  /// response. This can be sent by a server that is not configured to
  /// produce responses for the combination of scheme and authority that
  /// are included in the request URI.
  misdirectedRequest(421, 'Misdirected Request'),

  /// 422 Unprocessable Entity
  ///
  /// The request was well-formed but was unable to be followed due to
  /// semantic errors.
  unprocessableEntity(422, 'Unprocessable Entity'),

  /// 423 Locked
  ///
  /// The resource that is being accessed is locked.
  locked(423, 'Locked'),

  /// 424 Failed Dependency
  ///
  /// The request failed because it depended on another request and that
  /// request failed (e.g., a PROPPATCH).
  failedDependency(424, 'Failed Dependency'),

  /// 425 Too Early
  ///
  /// Indicates that the server is unwilling to risk processing a request that
  /// might be replayed.
  tooEarly(425, 'Too Early'),

  /// 426 Upgrade Required
  ///
  /// The server refuses to perform the request using the current protocol but
  /// might be willing to do so after the client upgrades to a different
  /// protocol. The server sends an Upgrade header in a 426 response to
  /// indicate the required protocol(s).
  upgradeRequired(426, 'Upgrade Required'),

  /// 428 Precondition Required
  ///
  /// The origin server requires the request to be conditional. This response
  /// is intended to prevent the 'lost update' problem, where a client
  /// GETs a resource's state, modifies it, and PUTs it back to the
  /// server, when meanwhile a third party has modified the state on the
  /// server, leading to a conflict.
  preconditionRequired(428, 'Precondition Required'),

  /// 429 Too Many Requests
  ///
  /// The user has sent too many requests in a given amount of time ("rate
  /// limiting").
  tooManyRequests(429, 'Many Requests'),

  /// 431 Request Header Fields Too Large
  ///
  /// The server is unwilling to process the request because its header fields
  /// are too large. The request may be resubmitted after reducing the
  /// size of the request header fields.
  requestHeaderFieldsTooLarge(431, 'Request Header Fields Too Large'),

  /// 451 Unavailable For Legal Reasons
  ///
  /// The user-agent requested a resource that cannot legally be provided,
  /// such as a web page censored by a government.
  unavailableForLegalReasons(451, 'Unavailable For Legal Reasons'),

  /// 500 Internal Server Error
  ///
  /// The server has encountered a situation it doesn't know how to handle.
  internalServerError(500, 'Internal Server Error'),

  /// 501 Not Implemented
  ///
  /// The request method is not supported by the server and cannot be handled.
  /// The only methods that servers are required to support (and therefore
  /// that must not return this code) are GET and HEAD.
  notImplemented(501, 'Not Implemented'),

  /// 502 Bad Gateway
  ///
  /// This error response means that the server, while working as a gateway to
  /// get a response needed to handle the request, got an invalid
  /// response.
  badGateway(502, 'Bad Gateway'),

  /// 503 Service Unavailable
  ///
  /// The server is not ready to handle the request. Common causes are a
  /// server that is down for maintenance or that is overloaded. Note that
  /// together with this response, a user-friendly page explaining the
  /// problem should be sent. This responses should be used for temporary
  /// conditions and the Retry-After: HTTP header should, if possible, contain
  /// the estimated time before the recovery of the service. The webmaster
  /// must also take care about the caching-related headers that are sent
  /// along with this response, as these temporary condition responses
  /// should usually not be cached.
  serviceUnavailable(503, 'Service Unavailable'),

  /// 504 Gateway Timeout
  ///
  /// This error response is given when the server is acting as a gateway and
  /// cannot get a response in time.
  gatewayTimeout(504, 'Gateway Timeout'),

  /// 505 HTTP Version Not Supported
  ///
  /// The HTTP version used in the request is not supported by the server.
  httpVersionNotSupported(505, 'HTTP Version Not Supported'),

  /// 506 Variant Also Negotiates
  ///
  /// The server has an internal configuration error: the chosen variant
  /// resource is configured to engage in transparent content negotiation
  /// itself, and is therefore not a proper end point in the negotiation
  /// process.
  variantAlsoNegotiates(506, 'Variant Also Negotiates'),

  /// 507 Insufficient Storage
  ///
  /// The server is unable to store the representation needed to complete the
  /// request.
  insufficientStorage(507, 'Insufficient Storage'),

  /// 508 Loop Detected
  ///
  /// The server detected an infinite loop while processing the request.
  loopDetected(508, 'Loop Detected'),

  /// 510 Not Extended
  ///
  /// Further extensions to the request are required for the server to fulfil
  /// it.
  notExtended(510, 'Not Extended'),

  /// 511 Network Authentication Required
  ///
  /// The 511 status code indicates that the client needs to authenticate to
  /// gain network access.
  networkAuthenticationRequired(511, 'Network Authentication Required'),

  // -------------------
  ;

  final int value;
  final String reason;
  const StatusCode(this.value, this.reason);
}
