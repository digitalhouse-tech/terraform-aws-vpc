variable "vpc" {
  type = object({
    name                  = string
    cidr                  = string
    secondary_cidr_blocks = optional(list(string), [])
    tags                  = optional(map(string), {})
    instance_tenancy      = optional(string, "default") # default, dedicated
    enable_dns_support    = optional(bool, true)        # true, false
    enable_dns_hostnames  = optional(bool, true)        # true, false
    nacl_default = optional(map(object({
      egress      = string # true, false
      rule_number = string # ACL entries are processed in ascending order by rule number
      rule_action = string # allow | deny
      from_port   = optional(string, "")
      to_port     = optional(string, "")
      icmp_code   = optional(string, "")
      # (Optional) ICMP protocol: The ICMP type. Required if specifying ICMP for the protocolE.g., -1
      icmp_type = optional(string, "")
      # (Optional) ICMP protocol: The ICMP code. Required if specifying ICMP for the protocolE.g., -1
      protocol   = string # A value of -1 means all protocols , tcp  - 6 ,
      cidr_block = optional(string, "")
      # The network range to allow or deny, in CIDR notation (for example 172.16.0.0/24 ).
      ipv6_cidr_block = optional(string, "")

    })), {})
    dhcp_options = optional(object({
      domain_name                       = optional(string, "")
      domain_name_servers               = optional(list(string), [])
      ntp_servers                       = optional(list(string), [])
      netbios_name_servers              = optional(list(string), [])
      netbios_node_type                 = optional(string, "")    # 1, 2, 4, 8  . default 2 . http://www.ietf.org/rfc/rfc2132.txt
      ipv6_address_preferred_lease_time = optional(string, "140") # 140 .. 2147483647 seconds . default 140
      tags                              = optional(map(string), {})
    }), {})
  })

  # Validation for CIDR format
  validation {
    condition     = can(cidrsubnet(var.vpc.cidr, 0, 0))
    error_message = "Invalid CIDR block format for VPC. CIDR block must be a valid subnet, e.g., 10.0.0.0/16."
  }

  # Validation for netbios_node_type field
  validation {
    condition = var.vpc.dhcp_options.netbios_node_type == "" || contains([
      "1", "2", "4", "8"
    ], var.vpc.dhcp_options.netbios_node_type)
    error_message = "Invalid value for netbios_node_type. Must be one of: 1, 2, 4, 8."
  }

  # Validation for ipv6_address_preferred_lease_time
  validation {
    condition = (
      var.vpc.dhcp_options.ipv6_address_preferred_lease_time == "" ||
      (
        length(var.vpc.dhcp_options.ipv6_address_preferred_lease_time) > 0 &&
        can(tonumber(var.vpc.dhcp_options.ipv6_address_preferred_lease_time)) &&
        tonumber(var.vpc.dhcp_options.ipv6_address_preferred_lease_time) >= 140 &&
        tonumber(var.vpc.dhcp_options.ipv6_address_preferred_lease_time) <= 2147483647
      )
    )
    error_message = "Invalid value for ipv6_address_preferred_lease_time. Must be a number between 140 and 2147483647 seconds."
  }
}

variable "tags_default" {
  type    = map(string)
  default = {}
}


variable "subnets" {
  type = object({
    public = optional(map(object({
      name = string
      cidr = string
      az   = string # Availability Zone or Availability Zone ID
      tags = optional(map(string), {})
      type = optional(string, "public") # any sort key for grouping . example , DB , WEB , APP , etc

      assign_ipv6_address_on_creation                = optional(bool, false)
      customer_owned_ipv4_pool                       = optional(string, "")
      enable_dns64                                   = optional(bool, false)
      enable_resource_name_dns_aaaa_record_on_launch = optional(bool, false)
      enable_resource_name_dns_a_record_on_launch    = optional(bool, true)
      ipv6_cidr_block                                = optional(string, "")
      ipv6_native                                    = optional(bool, false)
      map_customer_owned_ip_on_launch                = optional(bool, false)
      map_public_ip_on_launch                        = optional(bool, true)
      outpost_arn                                    = optional(string, "")
      private_dns_hostname_type_on_launch            = optional(string, "ip-name") #  The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID . Valid values:  ip-name, resource-name.
      nat_gateway                                    = optional(string, "")        #  DEFAULT - default nat gateway for all AZ  with SINGLE value
      nacl = optional(map(object({
        egress          = string # true, false
        rule_number     = string # ACL entries are processed in ascending order by rule number
        rule_action     = string # allow | deny
        from_port       = optional(string, "")
        to_port         = optional(string, "")
        icmp_code       = optional(string, "") # (Optional) ICMP protocol: The ICMP type. Required if specifying ICMP for the protocolE.g., -1
        icmp_type       = optional(string, "") # (Optional) ICMP protocol: The ICMP code. Required if specifying ICMP for the protocolE.g., -1
        protocol        = string               # A value of -1 means all protocols , tcp  - 6 ,
        cidr_block      = optional(string, "") # The network range to allow or deny, in CIDR notation (for example 172.16.0.0/24 ).
        ipv6_cidr_block = optional(string, "")

      })), {})

    })))
    private = optional(map(object({
      name                                           = string
      cidr                                           = string
      az                                             = string # Availability Zone or Availability Zone ID
      tags                                           = optional(map(string), {})
      type                                           = optional(string, "private") # any sort key for grouping . example , DB , WEB , APP , etc
      nat_gateway                                    = optional(string, "AZ")      # AZ - nat gateway for  each AZ , SINGLE - single nat gateway for all AZ (for this option you need to set nat_gateway=DEFAULT in one of the public networks)  ,SUBNET - dedicate nat gateway for each  subnet with SUBNET  type   ,  NONE - no nat gateway
      assign_ipv6_address_on_creation                = optional(bool, false)
      customer_owned_ipv4_pool                       = optional(string, "")
      enable_dns64                                   = optional(bool, false)
      enable_resource_name_dns_aaaa_record_on_launch = optional(bool, false)
      enable_resource_name_dns_a_record_on_launch    = optional(bool, false)
      ipv6_cidr_block                                = optional(string, "")
      ipv6_native                                    = optional(bool, false)
      map_customer_owned_ip_on_launch                = optional(bool, false)
      map_public_ip_on_launch                        = optional(bool, true)
      outpost_arn                                    = optional(string, "")
      private_dns_hostname_type_on_launch            = optional(string, "ip-name") #  The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID . Valid values:  ip-name, resource-name.
      nacl = optional(map(object({
        egress          = string # true, false
        rule_number     = string # ACL entries are processed in ascending order by rule number
        rule_action     = string # allow | deny
        from_port       = optional(string, "")
        to_port         = optional(string, "")
        icmp_code       = optional(string, "") # (Optional) ICMP protocol: The ICMP type. Required if specifying ICMP for the protocolE.g., -1
        icmp_type       = optional(string, "") # (Optional) ICMP protocol: The ICMP code. Required if specifying ICMP for the protocolE.g., -1
        protocol        = string               # A value of -1 means all protocols , tcp  - 6 ,
        cidr_block      = optional(string, "") # The network range to allow or deny, in CIDR notation (for example 172.16.0.0/24 ).
        ipv6_cidr_block = optional(string, "")

      })), {})

    })))
  })
  default = {
    public  = {}
    private = {}
  }

  validation {
    condition = alltrue([
      for _, subnet in coalesce(var.subnets.private, {}) : contains(["AZ", "SINGLE", "DEFAULT", "SUBNET", "NONE"], subnet.nat_gateway)
    ])
    error_message = "nat_gateway must be one of: AZ, SINGLE, DEFAULT, SUBNET, NONE."
  }

  validation {
    condition = alltrue([
      for _, subnet in coalesce(var.subnets.private, {}) : can(cidrsubnet(subnet.cidr, 0, 0))
    ])
    error_message = "Invalid CIDR block format. CIDR block must be a valid subnet, e.g., 10.10.16.0/24."
  }

  validation {
    condition = alltrue([
      for _, subnet in coalesce(var.subnets.private, {}) : contains(["ip-name", "resource-name"], subnet.private_dns_hostname_type_on_launch)
    ])
    error_message = "Invalid value for private_dns_hostname_type_on_launch. Must be one of: ip-name, resource-name."
  }

  validation {
    condition = alltrue([
      for _, subnet in coalesce(var.subnets.public, {}) : can(cidrsubnet(subnet.cidr, 0, 0))
    ])
    error_message = "Invalid CIDR block format. CIDR block must be a valid subnet, e.g., 10.10.16.0/24."
  }

  validation {
    condition = alltrue([
      for _, subnet in coalesce(var.subnets.public, {}) : contains(["ip-name", "resource-name"], subnet.private_dns_hostname_type_on_launch)
    ])
    error_message = "Invalid value for private_dns_hostname_type_on_launch. Must be one of: ip-name, resource-name."
  }
}

variable "existing_eip_ids_az" {
  description = "A map of existing Elastic IPs IDs to associate with the NAT Gateways where key is the AZ, value is the EIP ID"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for az, eip in var.existing_eip_ids_az : can(regex("^eipalloc-[0-9a-fA-F]{17}$", eip))
    ])
    error_message = "Each value in existing_eip_ids_az must be a valid Elastic IP ID (eipalloc-xxxxxxxxxxxxxxxxx)."
  }

  validation {
    condition = alltrue([
      for az, eip in var.existing_eip_ids_az : can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}[a-z]$", az))
    ])
    error_message = "Each key in existing_eip_ids_az must be a valid Availability Zone (e.g., eu-west-1a)."
  }
}
