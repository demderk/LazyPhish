//
//  WhoisCacheSingleton.swift
//  LazyPhish
//
//  Created by Roman Zheglov on 09.12.2024.
//


class WhoisCache {
    let defaultServer: WhoisServerInfo = .default
    
    static var staticStorage: [WhoisServerInfo] = [
        WhoisServerInfo(tld: "com", server: "whois.verisign-grs.com"),
        WhoisServerInfo(tld: "net", server: "whois.verisign-grs.com"),
        WhoisServerInfo(tld: "org", server: "whois.publicinterestregistry.org"),
        WhoisServerInfo(tld: "cn", server: "whois.cnnic.cn"),
        WhoisServerInfo(tld: "ai", server: "whois.nic.ai"),
        WhoisServerInfo(tld: "co", server: "whois.nic.co"),
        WhoisServerInfo(tld: "ca", server: "whois.cira.ca"),
        WhoisServerInfo(tld: "do", server: "whois.nic.do"),
        WhoisServerInfo(tld: "gl", server: "whois.nic.gl"),
        WhoisServerInfo(tld: "in", server: "whois.registry.in"),
        WhoisServerInfo(tld: "io", server: "whois.nic.io"),
        WhoisServerInfo(tld: "it", server: "whois.nic.it"),
        WhoisServerInfo(tld: "me", server: "whois.nic.me"),
        WhoisServerInfo(tld: "rs", server: "whois.rnids.rs"),
        WhoisServerInfo(tld: "so", server: "whois.nic.so"),
        WhoisServerInfo(tld: "us", server: "whois.nic.us"),
        WhoisServerInfo(tld: "ws", server: "whois.website.ws"),
        WhoisServerInfo(tld: "agency", server: "whois.nic.agency"),
        WhoisServerInfo(tld: "app", server: "whois.nic.google"),
        WhoisServerInfo(tld: "biz", server: "whois.nic.biz"),
        WhoisServerInfo(tld: "dev", server: "whois.nic.google"),
        WhoisServerInfo(tld: "house", server: "whois.nic.house"),
        WhoisServerInfo(tld: "info", server: "whois.nic.info"),
        WhoisServerInfo(tld: "link", server: "whois.uniregistry.net"),
        WhoisServerInfo(tld: "live", server: "whois.nic.live"),
        WhoisServerInfo(tld: "nyc", server: "whois.nic.nyc"),
        WhoisServerInfo(tld: "one", server: "whois.nic.one"),
        WhoisServerInfo(tld: "online", server: "whois.nic.online"),
        WhoisServerInfo(tld: "shop", server: "whois.nic.shop"),
        WhoisServerInfo(tld: "site", server: "whois.nic.site"),
        WhoisServerInfo(tld: "xyz", server: "whois.nic.xyz"),
        WhoisServerInfo(tld: "ru", server: "whois.tcinet.ru"),
        WhoisServerInfo(tld: "jp", server: "whois.jprs.jp"),
        WhoisServerInfo(tld: "fm", server: "whois.nic.fm"),
        WhoisServerInfo(tld: "gov", server: "whois.dotgov.gov"),
        WhoisServerInfo(tld: "uk", server: "whois.nic.uk"),
        WhoisServerInfo(tld: "ac.uk", server: "whois.ac.uk"),
        WhoisServerInfo(tld: "cz", server: "whois.nic.cz"),
        WhoisServerInfo(tld: "edu", server: "whois.educause.edu"),
        WhoisServerInfo(tld: "fr", server: "whois.nic.fr"),
        WhoisServerInfo(tld: "nl", server: "whois.domain-registry.nl"),
        WhoisServerInfo(tld: "tv", server: "whois.nic.tv"),
        WhoisServerInfo(tld: "cc", server: "ccwhois.verisign-grs.com"),
        WhoisServerInfo(tld: "br", server: "whois.registro.br"),
        WhoisServerInfo(tld: "la", server: "whois.nic.la"),
        WhoisServerInfo(tld: "ly", server: "whois.nic.ly"),
        WhoisServerInfo(tld: "be", server: "whois.dns.be"),
        WhoisServerInfo(name: "de", blinded: true),
        WhoisServerInfo(name: "eu", blinded: true),
        WhoisServerInfo(name: "es", blinded: true),
        WhoisServerInfo(name: "au", blinded: true),
        WhoisServerInfo(name: "mil", blinded: true),
        WhoisServerInfo(name: "gov.cn", blinded: true),
        WhoisServerInfo(name: "ae", blinded: true),
        WhoisServerInfo(name: "sa", blinded: true),
        WhoisServerInfo(name: "ro", blinded: true),
        WhoisServerInfo(name: "vn", blinded: true),
        WhoisServerInfo(name: "ir", blinded: true),
        WhoisServerInfo(name: "gr", blinded: true),
        WhoisServerInfo(name: "za", blinded: true),
        WhoisServerInfo(name: "bz", blinded: true),
        WhoisServerInfo(name: "pe", blinded: true),
        WhoisServerInfo(name: "az", blinded: true),
        WhoisServerInfo(name: "bd", blinded: true),
        WhoisServerInfo(name: "li", blinded: true),
        WhoisServerInfo(name: "lv", blinded: true)
    ]
    
    private var cache: Set<WhoisServerInfo> = []
    
    //MARK: Move to another place. FOR DEBUG ONLY
    
    public func getTLD(_ host: String) -> String {
        var tld: String = ""
        let toFind = Array(host.components(separatedBy: ".").reversed())
        tld = host.components(separatedBy: ".").last ?? ""
        if StrictURL.isTwoSLD(host: host) {
            tld = "\(toFind[1]).\(toFind[0])"
        }
        assert(!tld.isEmpty)
        return tld
    }
    
    /// Returns the cached server address if it exists
    func getCachedServer(_ host: String) -> WhoisServerInfo? {
        let tld: String = getTLD(host)
        return WhoisCache.staticStorage.first(where: { $0.tld == tld }) ?? cache.first(where: { $0.tld == tld })
    }
    
    /// Pushes the server address in the cache if it is not already present and returns pushed info.
    @discardableResult func push(host: String, server: String) -> (inserted: Bool, memberAfterInsert: WhoisServerInfo) {
        let tld = getTLD(host)
        let info = WhoisServerInfo(tld: tld, server: server)
        return cache.insert(info)
    }
    
    /// Returns the cached server address if it present, otherwise returns the default server.
    func pull(_ host: String) -> WhoisServerInfo {
        return getCachedServer(host) ?? defaultServer
    }
}
