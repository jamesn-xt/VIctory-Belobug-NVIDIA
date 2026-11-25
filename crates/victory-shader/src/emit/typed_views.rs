//! Host SRV component types and declared ranges for tracked guest descriptors.
use super::super::bitcode::Ty;
use super::Lower;
use crate::native::RootType;
use crate::resource::Source;

impl<'a> Lower<'a> {
    pub(super) fn scalar_uint_srv(&self, src: &Source, kind: u32) -> bool {
        if self.uint_srvs.is_empty() {
            return false;
        }
        let Source::Loaded { load, first } = src else { return false };
        let Some(address) = self.scalar.get(load) else { return false };
        let Some(root) = self.x.native.layout.get(address.param) else { return false };
        if root.root != RootType::Table || address.dynamic.is_some() || !address.offset.is_multiple_of(4) {
            return false;
        }
        self.uint_srvs.contains(&(root.slot, address.offset / 4 + u32::from(*first), kind))
    }

    pub(super) fn resource_return_type(&mut self, uint: bool) -> Ty {
        if uint {
            self.s.m.named_struct("dx.types.ResRet.i32", vec![self.s.t.i32; 5])
        } else {
            self.s.t.res_ret
        }
    }

}
