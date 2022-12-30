//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation

public protocol SSLPinning {
    
    func add(certificates: [String], for host: Host) async
    func getCredential(for protectionSpace: URLProtectionSpace) async -> URLCredential?
    
    func setup(with urlSessionDelegateWrapper: URLSessionDelegateWrapper) async
}

// swiftlint:disable line_length
public actor SSLPinner: SSLPinning {
    
    // MARK: Certificates
    private var certificates: [Host: [Certificate]] = [:]
    
    public init() { }
    
    public func add(certificates: [Base64String], for host: Host) async {
        if let existing = self.certificates[host] {
            let toAdd = certificates.filter({ new in
                return !existing.contains(where: { $0.string == new })
            })
            guard !toAdd.isEmpty else { return }
            self.certificates[host] = existing + toAdd.asCertificates
        } else {
            self.certificates[host] = certificates.asCertificates
        }
    }
    
    public func setup(with urlSessionDelegateWrapper: URLSessionDelegateWrapper) async {
        urlSessionDelegateWrapper.onDidReceiveChallenge = { [weak self] urlSession, challenge in
            if let credential = await self?.getCredential(for: challenge.protectionSpace) {
                return (.useCredential, credential)
            } else {
                return (.performDefaultHandling, nil)
            }
        }
    }
    
    public func getCredential(for protectionSpace: URLProtectionSpace) async -> URLCredential? {
        guard let certificates = certificates[protectionSpace.host],
              let trust = protectionSpace.serverTrust,
              protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              SecTrustGetCertificateCount(trust) > 0,
              let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0),
              certificates.contains(where: { localCertificate in
                  return localCertificate.validate(against: serverCertificate, using: trust)
              })
        else {
            return nil
        }
        
        return URLCredential(trust: trust)
    }
}

// MARK: Helpers
private struct Certificate: Equatable {
    
    let string: Base64String
    let certificate: SecCertificate
    let data: Data
    
    init?(from string: Base64String) {
        guard let data = Data(base64Encoded: string, options: []),
              let certificate = SecCertificateCreateWithData(nil, data as CFData)
        else { return nil }
        self.string = string
        self.data = data
        self.certificate = certificate
    }

    func validate(against serverCertificate: SecCertificate, using secTrust: SecTrust) -> Bool {
        let certificatesArray = [certificate] as CFArray
        SecTrustSetAnchorCertificates(secTrust, certificatesArray)
        
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(secTrust, &error)
        guard isValid && error == nil else { return false }
        
        let serverCertificateData = SecCertificateCopyData(certificate) as Data
        return serverCertificateData == data
    }
    
    static func == (lhs: Certificate, rhs: Certificate) -> Bool {
        return lhs.string == rhs.string
    }
}

private extension Array where Element == Base64String {
    
    var asCertificates: [Certificate] {
        return compactMap { certString -> Certificate? in
            guard let certificate = Certificate(from: certString) else {
                assertionFailure("failed to map certificate from \(certString)")
                return nil
            }
            return certificate
        }
    }
}
