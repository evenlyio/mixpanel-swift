//
//  Network.swift
//  Mixpanel
//
//  Created by Yarden Eitan on 6/2/16.
//  Copyright © 2016 Mixpanel. All rights reserved.
//

import Foundation


struct BasePath {
    static var MixpanelAPI = "https://api.mixpanel.com"

    static func buildURL(base: String, path: String) -> URL? {
        guard let url = URL(string: base)?.appendingPathComponent(path) else {
            return nil
        }

        return url
    }

}

enum Method: String {
    case GET
    case POST
}

struct Resource<A> {
    let path: String
    let method: Method
    let requestBody: Data?
    let headers: [String:String]
    let parse: (Data) -> A?
}

enum Reason {
    case ParseError
    case NoData
    case NotOKStatusCode(statusCode: Int)
    case Other(NSError)
}

class Network {

    class func apiRequest<A>(base: String,
                          resource: Resource<A>,
                          failure: (Reason, Data?, URLResponse?) -> (),
                          success: (A, URLResponse?) -> ()) {
        guard let request = buildURLRequest(base, resource: resource) else {
            return
        }

        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) -> Void in
            guard let httpResponse = response as? HTTPURLResponse else {
                failure(Reason.Other(error!), data, response)
                return
            }
            guard httpResponse.statusCode == 200 else {
                failure(Reason.NotOKStatusCode(statusCode: httpResponse.statusCode), data, response)
                return
            }
            guard let responseData = data else {
                failure(Reason.NoData, data, response)
                return
            }
            guard let result = resource.parse(responseData) else {
                failure(Reason.ParseError, data, response)
                return
            }

            success(result, response)
        }.resume()
    }

    private class func buildURLRequest<A>(_ base: String, resource: Resource<A>) -> URLRequest? {
        guard let url = BasePath.buildURL(base: base, path: resource.path) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = resource.requestBody

        for (k, v) in resource.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }
        return request as URLRequest
    }

    class func buildResource<A>(path: String,
                             method: Method,
                             requestBody: Data?,
                             headers: [String: String],
                             parse: (Data) -> A?) -> Resource<A> {
        return Resource(path: path, method: method, requestBody: requestBody, headers: headers, parse: parse)
    }

    class func trackIntegration(apiToken: String, completion: (Bool) -> ()) {
        let requestData = JSONHandler.encodeAPIData([["event": "Integration",
                                                      "properties": ["token": "85053bf24bba75239b16a601d9387e17",
                                                                     "mp_lib": "swift",
                                                                     "version": "3.0",
                                                                     "distinct_id": apiToken]]])

        let responseParser: (Data) -> Int? = { data in
            let response = String(data: data, encoding: String.Encoding.utf8)
            if let response = response {
                return Int(response) ?? 0
            }
            return nil
        }

        if let requestData = requestData {
            let requestBody = "ip=1&data=\(requestData)"
                .data(using: String.Encoding.utf8)

            let resource = Network.buildResource(path: FlushType.Events.rawValue,
                                                 method: Method.POST,
                                                 requestBody: requestBody,
                                                 headers: ["Accept-Encoding": "gzip"],
                                                 parse: responseParser)

            Network.apiRequest(base: BasePath.MixpanelAPI,
                               resource: resource,
                               failure: { (reason, data, response) in
                                Logger.debug(message: "failed to track integration")
                                completion(false)
                },
                               success: { (result, response) in
                                Logger.debug(message: "integration tracked")
                                completion(true)
                }
            )
        }
    }
}