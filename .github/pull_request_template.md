# Description

| General info   |                     |
| -------------- | ------------------- |
| ClickUp ticket | https://clickup.com |

Please include a summary of the change and which issue is fixed. Please also include relevant motivation and context. List any dependencies that are required for this change. This should include the ClickUp ticket.

Fixes # (issue)

## Type of change

Please delete options that are not relevant.

- Bug fix (non-breaking change which fixes an issue)
- New feature (non-breaking change which adds functionality)
- Breaking change (fix or feature that would cause existing functionality to not work as expected)
  - mobile
  - web
  - partner
  - other
- This change requires a documentation update

# How has this been tested?

Please describe the tests that you ran to verify your changes. Provide instructions so we can reproduce. Please also list any relevant details for your test configuration

- Unit tests
- Integration tests with Postgres
- Local tests with Postman
- Regression tests from quality-assurance repository

**Test Configuration**:

- Riva/business-api version:
- Wallet-api version :
- App version:
- Dashboard v2 version:

# Best Practices

- [ ] My code follows the [style guidelines of this project](https://github.com/skiprco/booking-api/blob/development/README.md)
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] I have made corresponding changes to the database and test fixtures
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] Any new or modified calls are reflected in postman collection
- [ ] I validated my development with the current frontend for retrocompatibilty (if needed)

# Security

**New Library (Packages, Dependencies) controls**

- [ ] New library has been approved by the Security Officer (AS PR REVIEWER, with explicit comment)[^so_approval]
- [ ] New library has been added to the [list of used libraries](https://docs.google.com/spreadsheets/d/1UsJ3KG_2qWKiJWbShxy9l53uuJLIDj9-wpjtwk2bxXU/edit#gid=993688960)
- [ ] New library is available under acceptable license[^licenses]
- [ ] New library has available support (library is receiving updates)
- [ ] New library is monitored in case of vulnerability alert (e.g. via dependabot)
- [ ] New library is compliant, if relevant, with Skipr's GDPR Policy
- [ ] New library is compliant with Skipr's Security Policies (ISO 27001)

**Common controls**

- [ ] I verified that my code does not allow SQL injections
- [ ] I verified that my code does not reveal any sensitive data
- [ ] I included access rules
- [ ] I validated all inputs
- [ ] I sanitized all inputs
- [ ] The libraries I used are up to date and without any known vulnerabilities
- [ ] I have added sufficient logs with correct severity in order to facilitate debugging

# Documentation

- [Top 10 vulnerability for this PR](https://owasp.org/www-project-top-ten/)
- [OWASP](https://github.com/OWASP/Go-SCP/blob/master/dist/go-webapp-scp.pdf)

# Footnotes

[^so_approval]:
    In case of new library, Security Officer must confirm explicit validation,
    Validation is requested via PR, and should be confirm with explicit comment.

[^licenses]: Use of libraries through any of following licenses is not allowed:

    - GNU General Public License (GPL)
    - GNU Lesser General Public License (LGPL)
    - GNU Affero General Public License (AGPL)
