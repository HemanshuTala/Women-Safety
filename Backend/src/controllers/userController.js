const User = require('../models/User');
const { generateCode } = require('../utils/helpers');
const mongoose = require('mongoose');

//
// 1. Generate Code
//
exports.generateCode = async (req, res, next) => {
  try {
    const { userId } = req.body;
    console.log('[generateCode] Request:', req.body);

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Valid userId is required' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (user.role !== 'user') {
      return res.status(403).json({ message: 'Only users can generate codes' });
    }

    const code = generateCode();
    user.linkingCode = code;
    user.linkingCodeExpiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour expiry

    await user.save();

    console.log(`[generateCode] Saved code ${code} for user ${user._id}`);
    return res.status(200).json({ code });
  } catch (err) {
    console.error('[generateCode] Error:', err);
    next(err);
  }
};

//
// 2. Link Parent
//
exports.linkParent = async (req, res, next) => {
  try {
    const { parentId, code } = req.body;
    console.log('[linkParent] Payload:', { parentId, code });

    if (!parentId || !mongoose.Types.ObjectId.isValid(parentId) || !code) {
      return res.status(400).json({ message: 'Valid parentId and code required' });
    }

    const parent = await User.findById(parentId);
    if (!parent) return res.status(404).json({ message: 'Parent not found' });
    if (parent.role !== 'parent') {
      return res.status(403).json({ message: 'Only parents can link to users' });
    }

    const user = await User.findOne({
      linkingCode: { $regex: `^${code}$`, $options: 'i' }, // Case-insensitive
      linkingCodeExpiresAt: { $gt: new Date() },
      role: 'user',
    });

    if (!user) {
      console.log('[linkParent] Invalid/expired code or user not found');
      return res.status(400).json({ message: 'Invalid or expired linking code' });
    }

    const alreadyLinked = user.relations?.some(
      (relId) => relId.toString() === parentId
    );
    if (alreadyLinked) {
      return res.status(409).json({ message: 'Already linked' });
    }

    user.relations.push(parentId);
    parent.relations.push(user._id);

    user.linkingCode = undefined;
    user.linkingCodeExpiresAt = undefined;
    parent.usedLinkingCode = undefined; // Clear used code

    await user.save();
    await parent.save();

    console.log(`[linkParent] Linked user ${user._id} with parent ${parent._id}`);
    return res.status(200).json({ message: 'Parent linked successfully' });
  } catch (err) {
    console.error('[linkParent] Error:', err);
    next(err);
  }
};

//
// 3. Get User with Linked Parents
//
exports.getUser = async (req, res, next) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Valid userId is required' });
    }

    const user = await User.findById(userId)
      .select('-password')
      .populate('relations', 'name email phone role');

    if (!user) return res.status(404).json({ message: 'User not found' });

    return res.status(200).json({ user });
  } catch (err) {
    console.error('[getUser] Error:', err);
    next(err);
  }
};

//
// 4. Get Parent with Linked Users (Children)
//
exports.getParent = async (req, res, next) => {
  try {
    const { parentId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(parentId)) {
      return res.status(400).json({ message: 'Valid parentId is required' });
    }

    const parent = await User.findById(parentId)
      .select('-password')
      .populate('relations', 'name _id email phone role');

    if (!parent) return res.status(404).json({ message: 'Parent not found' });

    if (parent.role !== 'parent') {
      return res.status(403).json({ message: 'Provided ID is not a parent user' });
    }

    return res.status(200).json({ parent });
  } catch (err) {
    console.error('[getParent] Error:', err);
    next(err);
  }
};