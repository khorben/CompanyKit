CompanyKit
==========

This project is about delivering a ready-to-use IT infrastructure suitable for
bootstrapping a small company, all self-hosted and supported by Open Source.

The first step consists in the generation of the configuration files relevant to
the initial set of services:

* Central authentication with [OpenLDAP](https://www.openldap.org/)
* DNS zone with BIND
* E-Mail infrastructure:
  * MX host with SpamAssassin
  * IMAP and SMTP host with [Dovecot 2](https://www.dovecot.org/) and
    [Postfix](https://www.postfix.org/)
  * Webmail host with [Roundcube](https://roundcube.net/)
* Groupware with [Nextcloud](https://www.nextcloud.com/) (CalDAV calendaring...)
* Development server with [Gitea](https://about.gitea.com/)
* Video-conferencing with [Jitsi Meet](https://jitsi.org/jitsi-meet/)
* Public website
* Reverse-proxy with [Nginx](https://nginx.org/)

Target Platform
---------------

The initial target platform is for a
[NetBSD](https://www.NetBSD.org/)/[EdgeBSD](https://www.edgebsd.org/) NVMM
hypervisor, and a collection of guest VMs, with the software deployed with
[pkgsrc](https://www.pkgsrc.org/).

Requirements
------------

The goal is to be able to host everything on a single physical server, with a
single public IP.

Guest VMs
---------

| Hostname | Purpose                                |
|----------|----------------------------------------|
| auth     | LDAP central authentication server     |
| cloud    | Nextcloud groupware instance           |
| git      | Development server                     |
| mail     | Mail server (sending and receiving)    |
| meet     | Video-conferencing server (all in one) |
| mx       | MX and anti-spam service (incoming)    |
| rproxy   | Reverse proxy for the infrastructure   |
| www      | Public web server                      |

Roadmap
-------

Ultimately, this project should be able to host multiple companies, with the
same set of services, on the same server.

This will be achieved as follows:

* E-Mail services:
  * Incoming e-mail can be routed by a frontal MX service
* HTTP services can be routed with virtual hosting through a frontal reverse
  proxy:
  * Groupware
  * Public website
  * Video-conferencing

Scaling
-------

Some of the services hosted support scaling in different ways, and may be
adapted in order to accommodate growing setups.

* Central authentication:
  * LDAP databases can be mirrored on slave servers.
* DNS:
  * Slave servers can easily be deployed.
* Video-conferencing:
  * Jitsi Meet offers a dedicated video relaying service, which can be spread
    across different hosts in order to serve more rooms in parallel.

