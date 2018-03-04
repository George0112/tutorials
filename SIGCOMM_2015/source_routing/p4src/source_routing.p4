/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "headers.p4"
#include "parsers.p4"

action _drop() {
    drop();
}

action action_pkt(port) {
	modify_field(standard_metadata.egress_spec, port);
}

action action_arp(port) {
	modify_field(standard_metadata.egress_spec, port);
}

action _route_arp () {
}

action _route_pkt () {
}

table route_arp {
	reads {
		arp.sender_ip_Addr: lpm;
	}
	actions {
		action_arp;
	}
	size: 2;
}

table ethType {
	reads {
		ethernet.etherType: exact;
	}
	actions {
		_route_arp;
		_route_pkt;
	}
	size: 1;
}

table route_pkt {
    reads {
        ipv4.dstAddr: lpm;
		svef.d: exact;
    }
    actions {
        _drop;
        action_pkt;
    }
    size: 3;
}

table table_drop {
	reads {
		svef.qid: exact;
	}
	actions {
		_drop;
	}
}

control ingress {
	if(ethernet.etherType == 0x0806) {
		apply(route_arp);
		if(svef.d == 1) {
			apply(table_drop);
		}
	}
	else {
		apply(route_pkt);
	}
}

control egress {
    // leave empty
}
