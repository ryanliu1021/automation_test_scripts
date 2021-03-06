## Create Aviatrix OnPrem gateway
## -----------------------------------
resource "aviatrix_gateway" "OnPrem-GW" {
    cloud_type = 1
    account_name = "${var.account_name}"
    gw_name = "${var.onprem_gw_name}"
    vpc_id = "vpc-94ca2efc"
    vpc_reg = "${var.region}"
    vpc_size = "${var.onprem_gw_size}"
    vpc_net = "172.16.0.0/16"
}
## END -------------------------------

## Create AWS customer gateway & VGW towards aviatrix OnPrem Gateway
## -----------------------------------------------------------------
resource "aws_customer_gateway" "customer_gateway" {
    bgp_asn    = 6588
    ip_address = "${aviatrix_gateway.OnPrem-GW.public_ip}"
    type       = "ipsec.1"
    tags {
       Name = "onprem-gateway"
    }
}
resource "aws_vpn_connection" "onprem" {
    vpn_gateway_id      = "${var.vgw_id}"
    customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
    type                = "ipsec.1"
    static_routes_only  = true
    tags {
       Name = "site2cloud-to-vgw"
    }
    depends_on = ["aviatrix_gateway.OnPrem-GW"]
}
    #vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
# original onprem CIDR block
resource "aws_vpn_connection_route" "onprem1" {
    count = "${var.onprem_count}"
    destination_cidr_block = "172.16.0.0/16"
    vpn_connection_id = "${aws_vpn_connection.onprem.id}"
}
# 2nd static route from onprem
resource "aws_vpn_connection_route" "onprem2" {
    count = "${var.onprem_count}"
    destination_cidr_block = "100.100.100.0/24"
    vpn_connection_id = "${aws_vpn_connection.onprem.id}"
}
## END -------------------------------

# Aviatrix site2cloud connection facing AWS VGW
## END -------------------------------
resource "aviatrix_site2cloud" "onprem-vgw" {
    vpc_id = "vpc-94ca2efc"
    gw_name = "${aviatrix_gateway.OnPrem-GW.gw_name}"
    conn_name = "s2c_to_vgw",
    remote_gw_type = "aws",
    remote_gw_ip = "${aws_vpn_connection.onprem.tunnel1_address}",
    remote_subnet = "${var.remote_subnet}",
    pre_shared_key = "${aws_vpn_connection.onprem.tunnel1_preshared_key}"
}
## END -------------------------------

